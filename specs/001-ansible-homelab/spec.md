# Feature Specification: Ansible Homelab Support

**Feature Branch**: `[001-ansible-homelab]`

**Created**: 2026-06-28

**Status**: Draft

**Input**: User description: "thêm hỗ trợ ansible nếu dùng homelab với 3 node và 2 worker"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-Click HA Cluster Deployment (Priority: P1)

As a homelab enthusiast, I want to use Ansible to automatically provision my entire 5-node K3s cluster (3 masters, 2 workers) so that I don't have to manually SSH into each node and run commands sequentially.

**Why this priority**: Automating the multi-node setup is the primary requested value. Manually coordinating an HA cluster (first master -> get token -> join other masters -> join workers) is tedious and prone to human error.

**Independent Test**: Can be fully tested by creating 5 fresh VMs, configuring the inventory, running the playbook, and verifying via `kubectl get nodes` that all 5 nodes are ready and part of the cluster.

**Acceptance Scenarios**:

1. **Given** 5 fresh VMs with SSH access and a configured Ansible inventory, **When** the user runs the deployment playbook, **Then** a highly available K3s cluster is formed with 3 control-plane nodes and 2 worker nodes.
2. **Given** a partially failed deployment due to network timeout, **When** the user re-runs the playbook, **Then** Ansible idempotently completes the setup without breaking already installed nodes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a sample Ansible inventory structure pre-configured for a 3-master, 2-worker topology.
- **FR-002**: System MUST orchestrate the installation sequence strictly: First Master -> Additional Masters -> Workers.
- **FR-003**: System MUST automatically retrieve the `node-token` from the first master and securely pass it to the remaining nodes without requiring user copy-pasting.
- **FR-004**: System MUST leverage the existing `installer.sh` script via non-interactive CLI flags (`--ha-first`, `--ha-join`, `--worker`).
- **FR-005**: System MUST allow users to easily configure the First Master IP within the Ansible variables.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can completely provision a 5-node K3s HA cluster with a single Ansible command.
- **SC-002**: Zero manual SSH logins are required by the user to retrieve tokens or execute scripts.
- **SC-003**: The entire Ansible deployment process completes in under 10 minutes (assuming standard internet speed).

## Assumptions

- Users have Ansible installed on their local control machine.
- Target homelab nodes have SSH enabled, Python installed (required by Ansible), and passwordless `sudo` privileges configured for the Ansible user.
- Target nodes are running supported operating systems (Ubuntu 22.04/24.04/26.04 or Debian 12/13).
- The network allows traffic on port 6443 between nodes.
