# Data Model & Configuration Structure

## Ansible Inventory Structure

The data model for this feature is represented by the Ansible Inventory YAML format. It defines the logical grouping of nodes required for the `installer.sh` logic.

### Groups
- `k3s_first_master`: Must contain exactly one node. This is where `--ha-first` is executed.
- `k3s_join_masters`: Contains additional control-plane nodes. These execute `--ha-join`.
- `k3s_workers`: Contains worker nodes. These execute `--worker`.

### Variables
- `ansible_user`: The SSH user to connect as (e.g., `root` or `ubuntu`). Must have sudo privileges.
- `k3s_master_ip`: A dynamic variable that extracts the IP address of the node in `k3s_first_master` so that subsequent nodes know where to connect.
