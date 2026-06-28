#!/bin/bash
# Install from GitHub with:
# curl -fsSL https://raw.githubusercontent.com/kienle1819/k3s-installer/main/installer.sh | bash

set -euo pipefail

# Configuration
CALICO_VERSION="v3.28.5"
K3S_VERSION="v1.32.6+k3s1"
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
LOG_FILE="/tmp/k3s-setup-$(date +%Y%m%d-%H%M%S).log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)" 2>/dev/null || SCRIPT_DIR="/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Error handler
error_handler() {
    local line_number="$1"
    log "ERROR" "Script failed at line $line_number"
    log "ERROR" "Check log file: $LOG_FILE"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log "ERROR" "This script should not be run as root"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log "INFO" "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log "ERROR" "Cannot determine OS version"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        log "WARN" "This script is designed for Ubuntu/Debian. Proceeding anyway..."
    fi
    
    # Check architecture
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" ]] && [[ "$arch" != "aarch64" ]]; then
        log "WARN" "Architecture $arch may not be fully supported"
    fi
    
    # Check memory
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $mem_gb -lt 2 ]]; then
        log "WARN" "System has less than 2GB RAM. K3s may not perform well."
    fi
    
    # Check disk space
    local disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $disk_gb -lt 10 ]]; then
        log "WARN" "Less than 10GB free disk space available"
    fi
    
    # Check if K3s is already installed
    if command -v k3s >/dev/null 2>&1; then
        log "WARN" "K3s appears to be already installed"
        read -p "Continue anyway? (y/N): " -n 1 -r < /dev/tty
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log "INFO" "System requirements check completed"
}

# Auto detect primary IP
detect_ip() {
    local ip
    # Try multiple methods to detect IP
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}') || \
    ip=$(hostname -I | awk '{print $1}') || \
    ip=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    
    if [[ -z "$ip" ]]; then
        log "ERROR" "Could not detect IP address"
        return 1
    fi
    
    echo "$ip"
}

# Validate IP address
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Update system packages
update_system() {
    log "INFO" "Updating system packages..."
    sudo apt-get update -qq || {
        log "ERROR" "Failed to update package lists"
        return 1
    }
}

# Load kernel modules (without IPVS)
load_kernel_modules() {
    log "INFO" "Loading kernel modules for container networking..."
    local modules=(nf_conntrack br_netfilter overlay)
    
    for mod in "${modules[@]}"; do
        if ! lsmod | grep -q "^$mod "; then
            log "INFO" "Loading module: $mod"
            sudo modprobe "$mod" || {
                log "WARN" "Failed to load module: $mod"
            }
        else
            log "DEBUG" "Module $mod already loaded"
        fi
    done
    
    # Make modules persistent
    log "INFO" "Making kernel modules persistent..."
    sudo mkdir -p /etc/modules-load.d
    printf '%s\n' "${modules[@]}" | sudo tee /etc/modules-load.d/k3s.conf >/dev/null
}

# Install required packages (without IPVS packages)
install_packages() {
    log "INFO" "Installing required packages..."
    local packages=(curl)
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        else
            log "DEBUG" "$pkg already installed"
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log "INFO" "Installing: ${to_install[*]}"
        sudo apt-get install -y "${to_install[@]}" || {
            log "ERROR" "Failed to install packages"
            return 1
        }
    else
        log "INFO" "All required packages are already installed"
    fi
}

# Wait for node to be ready
wait_for_node() {
    log "INFO" "Waiting for node to be ready..."
    local max_attempts=60
    local attempt=1
    local sleep_interval=5
    
    while [[ $attempt -le $max_attempts ]]; do
        local node_status
        node_status=$(kubectl get nodes --no-headers -o custom-columns=STATUS:.status.conditions[-1].type 2>/dev/null | head -1)
        
        if [[ "$node_status" == "Ready" ]]; then
            local node_name
            node_name=$(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name | head -1)
            log "INFO" "Node '$node_name' is ready!"
            
            # Show detailed node info
            kubectl get nodes -o wide
            return 0
        fi
        
        # Show current status for debugging
        local current_status
        current_status=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' | head -1)
        log "INFO" "Node status: ${current_status:-"Unknown"} (attempt $attempt/$max_attempts)"
        
        # Show any issues with the node
        if [[ $attempt -gt 10 ]]; then
            log "DEBUG" "Node conditions:"
            kubectl describe node 2>/dev/null | grep -A 10 "Conditions:" || true
        fi
        
        sleep $sleep_interval
        ((attempt++))
    done
    
    log "ERROR" "Node failed to become ready within $((max_attempts * sleep_interval)) seconds"
    log "ERROR" "Current node status:"
    kubectl get nodes 2>/dev/null || log "ERROR" "Cannot get node status"
    return 1
}

# Wait for pods to be ready
wait_for_pods() {
    local namespace="$1"
    local label_selector="$2"
    local timeout="${3:-300}"
    
    log "INFO" "Waiting for pods in namespace $namespace with selector $label_selector..."
    
    # First wait for pods to be created
    local max_attempts=$((timeout / 10))
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        local pod_count
        pod_count=$(kubectl get pods -n "$namespace" -l "$label_selector" --no-headers 2>/dev/null | wc -l)
        
        if [[ $pod_count -gt 0 ]]; then
            log "INFO" "Found $pod_count pod(s) with selector $label_selector"
            break
        fi
        
        log "INFO" "Waiting for pods to be created... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        log "ERROR" "No pods found with selector $label_selector in namespace $namespace"
        log "DEBUG" "Available pods in namespace $namespace:"
        kubectl get pods -n "$namespace" 2>/dev/null || log "DEBUG" "Namespace $namespace not found or no pods"
        return 1
    fi
    
    # Now wait for pods to be ready
    log "INFO" "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod \
        -l "$label_selector" \
        -n "$namespace" \
        --timeout="${timeout}s" || {
        log "ERROR" "Pods failed to become ready within timeout"
        log "DEBUG" "Pod status:"
        kubectl get pods -n "$namespace" -l "$label_selector" -o wide 2>/dev/null || true
        return 1
    }
    
    log "INFO" "All pods with selector $label_selector are ready"
}

# Wait for entire cluster (nodes and system pods) to be ready
wait_for_cluster_ready() {
    log "INFO" "Waiting for the cluster to become fully ready (this may take a few minutes)..."
    
    # 1. Wait for node to be ready
    wait_for_node || log "WARN" "Nodes are taking longer than expected to become ready"
    
    # 2. Wait for system pods
    local namespaces=("kube-system" "calico-system" "tigera-operator")
    local max_attempts=30
    local attempt=1
    local sleep_interval=10
    
    while [[ $attempt -le $max_attempts ]]; do
        local not_ready_count=0
        
        for ns in "${namespaces[@]}"; do
            # Find pods that are NOT Running and NOT Completed
            local pending_pods
            pending_pods=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | awk '{print $3}' | grep -Ev 'Running|Completed' || true)
            
            if [[ -n "$pending_pods" ]]; then
                local count
                count=$(echo "$pending_pods" | wc -w)
                not_ready_count=$((not_ready_count + count))
            fi
        done
        
        if [[ $not_ready_count -eq 0 ]]; then
            log "INFO" "All system pods are ready!"
            return 0
        fi
        
        log "INFO" "Waiting for $not_ready_count system pod(s) to become ready... (attempt $attempt/$max_attempts)"
        sleep $sleep_interval
        ((attempt++))
    done
    
    log "WARN" "Some system pods did not become ready within the timeout period."
    log "DEBUG" "Current pod status:"
    kubectl get pods -A 2>/dev/null || true
    return 0
}

# Install Calico with proper CRD waiting
install_calico() {
    log "INFO" "Installing Calico $CALICO_VERSION..."
    
    # Install Tigera operator
    kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml" || {
        log "ERROR" "Failed to install Tigera operator"
        return 1
    }
    
    # Wait for tigera-operator namespace to be created
    log "INFO" "Waiting for tigera-operator namespace..."
    local attempt=1
    while [[ $attempt -le 30 ]]; do
        if kubectl get namespace tigera-operator &>/dev/null; then
            log "INFO" "tigera-operator namespace is ready"
            break
        fi
        log "INFO" "Waiting for tigera-operator namespace... (attempt $attempt/30)"
        sleep 5
        ((attempt++))
    done
    
    # Wait for Tigera operator to be ready
    log "INFO" "Waiting for Tigera operator deployment..."
    wait_for_pods "tigera-operator" "k8s-app=tigera-operator" 180 || {
        log "WARN" "Tigera operator pods not ready, but continuing..."
    }
    
    # Wait for CRDs to be created by checking for specific CRDs
    log "INFO" "Waiting for Calico CRDs to be created..."
    local crds=("installations.operator.tigera.io" "apiservers.operator.tigera.io" "imagesets.operator.tigera.io")
    local max_crd_wait=60
    local crd_attempt=1
    
    while [[ $crd_attempt -le $max_crd_wait ]]; do
        local all_crds_ready=true
        
        for crd in "${crds[@]}"; do
            if ! kubectl get crd "$crd" &>/dev/null; then
                all_crds_ready=false
                break
            fi
        done
        
        if [[ "$all_crds_ready" == "true" ]]; then
            log "INFO" "All required CRDs are available"
            break
        fi
        
        log "INFO" "Waiting for CRDs to be created... (attempt $crd_attempt/$max_crd_wait)"
        sleep 5
        ((crd_attempt++))
    done
    
    if [[ $crd_attempt -gt $max_crd_wait ]]; then
        log "ERROR" "CRDs not created within timeout"
        log "DEBUG" "Available CRDs:"
        kubectl get crd | grep tigera || log "DEBUG" "No Tigera CRDs found"
        return 1
    fi
    
    # Additional wait to ensure operator is fully ready
    log "INFO" "Waiting for operator to be fully ready..."
    sleep 10
    
    # Verify operator is actually ready by checking deployment status
    if ! kubectl get deployment tigera-operator -n tigera-operator -o jsonpath='{.status.readyReplicas}' | grep -q "1"; then
        log "WARN" "Tigera operator may not be fully ready, but proceeding..."
    fi
    
    # Install Calico custom resources with retry mechanism
    log "INFO" "Installing Calico custom resources..."
    local retry_count=0
    local max_retries=3
    
    while [[ $retry_count -lt $max_retries ]]; do
        if kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/custom-resources.yaml"; then
            log "INFO" "Calico custom resources installed successfully"
            break
        else
            ((retry_count++))
            if [[ $retry_count -lt $max_retries ]]; then
                log "WARN" "Failed to install custom resources, retrying in 15 seconds... (attempt $retry_count/$max_retries)"
                sleep 15
            else
                log "ERROR" "Failed to install Calico custom resources after $max_retries attempts"
                return 1
            fi
        fi
    done
    
    # Wait for calico-system namespace to be created
    log "INFO" "Waiting for calico-system namespace..."
    attempt=1
    while [[ $attempt -le 30 ]]; do
        if kubectl get namespace calico-system &>/dev/null; then
            log "INFO" "calico-system namespace is ready"
            break
        fi
        log "INFO" "Waiting for calico-system namespace... (attempt $attempt/30)"
        sleep 5
        ((attempt++))
    done
    
    # Wait for Calico components to be ready
    log "INFO" "Waiting for Calico components to be ready..."
    
    # Wait for calico-kube-controllers
    wait_for_pods "calico-system" "k8s-app=calico-kube-controllers" 300 || {
        log "WARN" "Calico kube-controllers not ready, but continuing..."
    }
    
    # Wait for calico-node daemonset
    wait_for_pods "calico-system" "k8s-app=calico-node" 300 || {
        log "WARN" "Calico node pods not ready, but continuing..."
    }
    
    # Check overall Calico status
    log "INFO" "Calico installation status:"
    kubectl get pods -n calico-system -o wide 2>/dev/null || log "WARN" "Could not get calico-system pods"
    kubectl get pods -n tigera-operator -o wide 2>/dev/null || log "WARN" "Could not get tigera-operator pods"
    
    return 0
}

# Install K3s
install_k3s() {
    log "INFO" "Starting K3s installation..."
    
    check_root
    check_requirements
    update_system
    load_kernel_modules
    install_packages
    
    # Detect and validate IP
    local detected_ip
    detected_ip=$(detect_ip) || {
        log "ERROR" "Failed to detect IP address"
        exit 1
    }
    
    local server_ip
    read -p "👉 Detected server IP is '$detected_ip'. Press Enter to accept or input a different IP: " server_ip < /dev/tty
    server_ip=${server_ip:-$detected_ip}
    
    if ! validate_ip "$server_ip"; then
        log "ERROR" "Invalid IP address: $server_ip"
        exit 1
    fi
    
    log "INFO" "Using server IP: $server_ip"
    
    # Install K3s (without IPVS configuration)
    log "INFO" "Installing K3s version $K3S_VERSION..."
    curl -sfL https://get.k3s.io | \
        INSTALL_K3S_VERSION="$K3S_VERSION" \
        INSTALL_K3S_EXEC="\
        --disable traefik,servicelb \
        --disable-cloud-controller \
        --flannel-backend=none \
        --disable-network-policy \
        --tls-san $server_ip \
        --kubelet-arg cloud-provider=external \
        --service-cidr=10.55.55.0/24" \
        K3S_KUBECONFIG_MODE="644" \
        sh - || {
        log "ERROR" "K3s installation failed"
        exit 1
    }
    
    # Update kubeconfig
    log "INFO" "Updating kubeconfig with server IP..."
    sudo sed -i "s/127.0.0.1/$server_ip/" "$KUBECONFIG_PATH"
    export KUBECONFIG="$KUBECONFIG_PATH"
    
    # Wait for node to be ready
    wait_for_node || {
        log "ERROR" "Node failed to become ready"
        exit 1
    }
    
    # Show node status
    kubectl get nodes -o wide
    
    # Remove cloud provider taint
    log "INFO" "Removing cloud provider taint..."
    kubectl taint nodes --all node.cloudprovider.kubernetes.io/uninitialized=false:NoSchedule- || {
        log "WARN" "Failed to remove taint (may not exist)"
    }
    
    # Install Calico
    install_calico || {
        log "ERROR" "Calico installation failed"
        exit 1
    }
    
    # Install Helm if not present
    if ! command -v helm >/dev/null 2>&1; then
        log "INFO" "Installing Helm 3..."
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || {
            log "ERROR" "Failed to install Helm"
            exit 1
        }
    else
        log "INFO" "Helm is already installed"
    fi
    
    # Create kubectl alias
    log "INFO" "Creating kubectl alias..."
    {
        echo "export KUBECONFIG=$KUBECONFIG_PATH"
        echo "alias k='kubectl'"
        echo "complete -F __start_kubectl k"
    } >> ~/.bash_aliases
    
    # Create completion
    if [[ -f /usr/share/bash-completion/completions/kubectl ]]; then
        source /usr/share/bash-completion/completions/kubectl
    fi
    
    # Set timezone to Asia/Ho_Chi_Minh
    log "INFO" "Setting system timezone to Asia/Ho_Chi_Minh..."
    sudo ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime || {
        log "WARN" "Failed to set timezone"
    }

    # Add cron job to drop caches every 59 minutes
    log "INFO" "Adding cron job to drop memory caches every 59 minutes..."
    local cron_entry="*/59 * * * * sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null"
    (sudo crontab -l 2>/dev/null | grep -v "drop_caches"; echo "$cron_entry") | sudo crontab - || {
        log "WARN" "Failed to add cron job"
    }

    # Wait for all components to be fully ready
    wait_for_cluster_ready
    
    log "INFO" "✅ K3s $K3S_VERSION with Calico has been installed successfully!"
    log "INFO" "📝 Note: IPVS support has been skipped - using default iptables proxy mode"
    log "INFO" "Log file: $LOG_FILE"
    log "INFO" "Kubeconfig: $KUBECONFIG_PATH"
    log "INFO" "Run 'source ~/.bash_aliases' to enable the 'k' alias"
    
    # Show cluster info
    echo -e "\n${GREEN}=== Cluster Information ===${NC}"
    kubectl cluster-info
    echo -e "\n${GREEN}=== Node Status ===${NC}"
    kubectl get nodes -o wide
    echo -e "\n${GREEN}=== Pod Status ===${NC}"
    kubectl get pods -A
}

# Uninstall K3s
uninstall_k3s() {
    log "INFO" "Starting K3s uninstallation..."
    
    if [[ -f "$KUBECONFIG_PATH" ]]; then
        export KUBECONFIG="$KUBECONFIG_PATH"
        
        log "INFO" "Current nodes in cluster:"
        kubectl get nodes 2>/dev/null || log "WARN" "Could not fetch nodes"
        
        read -p "👉 Enter the node name to delete from cluster (or press Enter to skip): " node_name < /dev/tty
        if [[ -n "$node_name" ]]; then
            log "INFO" "Deleting node $node_name from cluster..."
            kubectl delete node "$node_name" 2>/dev/null || log "WARN" "Failed to delete node or node not found"
        fi
    fi
    
    # Uninstall K3s
    if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
        log "INFO" "Running K3s uninstaller..."
        sudo /usr/local/bin/k3s-uninstall.sh || log "WARN" "K3s uninstaller reported errors"
    else
        log "WARN" "K3s uninstaller not found - K3s may not be installed"
    fi
    
    # Clean up kernel modules configuration
    if [[ -f /etc/modules-load.d/k3s.conf ]]; then
        log "INFO" "Removing kernel modules configuration..."
        sudo rm -f /etc/modules-load.d/k3s.conf
    fi
    
    # Clean up bash aliases
    if [[ -f ~/.bash_aliases ]]; then
        log "INFO" "Cleaning up bash aliases..."
        sed -i '/KUBECONFIG.*k3s/d' ~/.bash_aliases
        sed -i '/alias k=/d' ~/.bash_aliases
    fi
    
    log "INFO" "✅ K3s has been uninstalled successfully!"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help message
    -v, --version   Show script version
    -l, --log       Specify log file location
    
Interactive mode will be started if no options are provided.
EOF
}

# Show version
show_version() {
    echo "K3s + Calico Setup Script v2.0 (No IPVS)"
    echo "K3s version: $K3S_VERSION"
    echo "Calico version: $CALICO_VERSION"
    echo "Proxy mode: iptables (IPVS disabled)"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main menu
main_menu() {
    echo -e "${BLUE}==============================${NC}"
    echo -e "${BLUE}  K3s + Calico Setup (No IPVS)${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo "1) Install K3s + Calico"
    echo "2) Uninstall K3s"
    echo "3) Show cluster status"
    echo "4) Show logs"
    echo "5) Exit"
    echo -e "${BLUE}------------------------------${NC}"
    read -p "Choose an option (1-5): " action < /dev/tty
    
    case "$action" in
        1)
            install_k3s
            ;;
        2)
            uninstall_k3s
            ;;
        3)
            if [[ -f "$KUBECONFIG_PATH" ]]; then
                export KUBECONFIG="$KUBECONFIG_PATH"
                echo -e "\n${GREEN}=== Cluster Info ===${NC}"
                kubectl cluster-info 2>/dev/null || echo "Cluster not available"
                echo -e "\n${GREEN}=== Nodes ===${NC}"
                kubectl get nodes -o wide 2>/dev/null || echo "No nodes found"
                echo -e "\n${GREEN}=== All Pods ===${NC}"
                kubectl get pods -A 2>/dev/null || echo "No pods found"
            else
                log "ERROR" "Kubeconfig not found. Is K3s installed?"
            fi
            ;;
        4)
            if [[ -f "$LOG_FILE" ]]; then
                tail -20 "$LOG_FILE"
            else
                log "ERROR" "Log file not found: $LOG_FILE"
            fi
            ;;
        5)
            log "INFO" "Exiting..."
            exit 0
            ;;
        *)
            log "ERROR" "Invalid choice: $action"
            exit 1
            ;;
    esac
}

# Initialize logging
log "INFO" "Starting K3s + Calico setup script (No IPVS)"
log "INFO" "Log file: $LOG_FILE"

# Run main menu (auto-install if piped, otherwise show menu)
if [[ -t 0 ]]; then
    # Running in terminal - show interactive menu
    main_menu
else
    # Running via pipe (curl | bash) - auto-install
    log "INFO" "Running in non-interactive mode. Starting K3s installation..."
    install_k3s
fi
