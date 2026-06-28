# Product Specification: k3s-installer

## 1. Project Overview
**k3s-installer** is an automated Bash script designed to streamline the deployment of K3s clusters with Calico CNI (replacing the default Flannel) without using IPVS. It supports deploying standalone masters, High Availability (HA) multi-node masters (using Embedded etcd), and worker nodes in a highly automated or interactive manner.

## 2. Supported Environments
- **Operating Systems**: 
  - Ubuntu (22.04, 24.04, 26.04)
  - Debian (12, 13)
- **Privileges**: Requires `root` access (script enforces `EUID == 0`).
- **Dependencies Installed by Script**: `curl`, `helm`.

## 3. Core Software Versions
*Note: Versions are hardcoded as defaults but can be bumped in the script.*
- **K3s**: `v1.36.2+k3s1`
- **Calico**: `v3.32.1`

## 4. Architecture & Modes of Operation
The script (`installer.sh`) can be executed via an interactive CLI menu or fully automated via command-line flags.

### 4.1. Installation Modes
1. **First Master Node (HA Support)**: 
   - Initializes a new cluster using `--cluster-init`.
   - Uses embedded etcd for data storage to support future master nodes.
   - Installs Calico as the primary CNI.
2. **Additional Master Node (HA Join)**:
   - Joins an existing cluster as a control-plane node.
   - Requires the First Master IP and the Node Token.
   - Skips Calico installation (relies on the first master's deployment).
3. **Worker Node**:
   - Joins an existing cluster as a data-plane node (agent).
   - Requires the Master IP and the Node Token.

### 4.2. K3s Custom Configurations
The K3s installation process is customized with the following flags (`INSTALL_K3S_EXEC`):
- `--disable traefik,servicelb`: Disables default ingress and load balancer.
- `--disable-cloud-controller`: Disables default cloud controller.
- `--flannel-backend=none`: Disables default Flannel CNI.
- `--disable-network-policy`: Defers network policy to Calico.
- `--kubelet-arg cloud-provider=external`: Prepares for external cloud providers.
- `--service-cidr=10.55.55.0/24`: Custom service CIDR to avoid conflicts.

## 5. Command-Line Interface (CLI)
The script provides the following flags for non-interactive execution:
- `-h, --help`: Displays help and usage documentation.
- `-v, --version`: Displays current script, K3s, and Calico versions.
- `-l, --log <path>`: Specifies a custom path for the installation log.
- `--ha-first`: Triggers the First Master installation mode.
- `--ha-join`: Triggers the Additional Master installation mode.
- `-w, --worker`: Triggers the Worker Node installation mode.
- `-m, --master-ip <IP>`: Specifies the target Master IP (required for `--ha-join` and `-w`).
- `-t, --token <TOKEN>`: Specifies the authentication token (required for `--ha-join` and `-w`).

## 6. Logic Flow (Main Setup Process)
1. **Pre-flight Checks**: Verify root permissions and valid OS distribution.
2. **System Update**: Run `apt-get update`.
3. **Kernel Modules**: Load `nf_conntrack`, `br_netfilter`, and `overlay` persistently.
4. **Package Installation**: Install `curl`.
5. **K3s Installation**: Execute the official K3s installation script with pre-defined environment variables.
6. **Wait for Node Readiness**: Poll Kubernetes API until the node status is `Ready`.
7. **Calico Installation (Master Only)**: 
   - Apply Tigera Operator manifest.
   - Apply Calico custom resources.
   - Poll and wait until `calico-system` and `tigera-operator` pods are fully running.
8. **Helm Installation**: Download and install Helm 3 binary if not present.

## 7. Uninstallation & Cleanup
The script provides a smart uninstallation routine:
- Detects whether the current node is a Master (`k3s-uninstall.sh`) or a Worker (`k3s-agent-uninstall.sh`).
- Removes the specific node from the cluster.
- Cleans up leftover directories (`/etc/rancher`, `/var/lib/rancher`, `/var/lib/cni`, etc.).
- Cleans up CNI network interfaces and `iptables`/`ipvsadm` rules.
- Removes K3s aliases from `~/.bash_aliases`.
