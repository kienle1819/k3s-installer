# Phase 0: Research & Architecture

## Unknowns Resolved

1. **How to securely extract the token from the first master without manual intervention?**
   - **Decision**: Use Ansible's `slurp` module to read `/var/lib/rancher/k3s/server/node-token` on the first master, decode it from base64, and store it as a host fact (`hostvars['master1']['k3s_token']`).
   - **Rationale**: `slurp` is built-in, secure, and doesn't require downloading the file to the local disk. Setting it as a fact makes it available to subsequent plays for other nodes.
   - **Alternatives considered**: `fetch` module (leaves a file on the control node, which is a security risk).

2. **How to execute the `installer.sh` on target nodes?**
   - **Decision**: Use the Ansible `script` module.
   - **Rationale**: The `script` module transfers a local script to the remote node and executes it, which perfectly matches our architecture of keeping `installer.sh` as the single source of truth without relying on downloading it from GitHub during Ansible execution.
   - **Alternatives considered**: `copy` then `command` (two steps instead of one), or `shell` with `curl | bash` (depends on GitHub being reachable and up to date, harder to test local changes).

3. **How to handle execution ordering?**
   - **Decision**: Split the playbook into three sequential plays targeting different inventory groups:
     1. Play 1: Targets `k3s_first_master`. Runs `installer.sh --ha-first` and retrieves the token.
     2. Play 2: Targets `k3s_join_masters`. Runs `installer.sh --ha-join -m <ip> -t <token>`.
     3. Play 3: Targets `k3s_workers`. Runs `installer.sh --worker -m <ip> -t <token>`.
   - **Rationale**: Strict isolation guarantees that subsequent nodes don't attempt to join before the cluster is initialized or the token is available.
