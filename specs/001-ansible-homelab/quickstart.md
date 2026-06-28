# Ansible Homelab Quickstart

This guide explains how to quickly provision a 5-node HA K3s cluster using the provided Ansible playbook.

## Prerequisites

- Local machine with Ansible installed (`ansible-core` >= 2.12).
- 5 nodes (Ubuntu or Debian) accessible via SSH.
- Passwordless `sudo` configured for the SSH user on all nodes.

## Setup

1. Copy the example inventory to a local file:
   ```bash
   cp ansible/inventory.example.yml inventory.yml
   ```

2. Edit `inventory.yml` to match your node IP addresses and SSH user:
   ```bash
   nano inventory.yml
   ```
   Ensure you place exactly 1 IP under `k3s_first_master`, 2 IPs under `k3s_join_masters`, and 2 IPs under `k3s_workers`.

## Run the Playbook

Execute the deployment playbook targeting your inventory:

```bash
ansible-playbook -i inventory.yml ansible/deploy-k3s.yml
```

## Expected Outcome

1. The playbook connects to the first master and initializes the cluster (`--ha-first`).
2. It retrieves the node token.
3. It connects to the remaining masters in parallel and joins them to the control plane (`--ha-join`).
4. Finally, it connects to the workers in parallel and joins them to the data plane (`--worker`).
5. When finished, log into your first master and run `kubectl get nodes`. You should see 5 `Ready` nodes.
