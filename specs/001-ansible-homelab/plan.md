# Implementation Plan: Ansible Homelab Support

**Branch**: `[001-ansible-homelab]` | **Date**: 2026-06-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/001-ansible-homelab/spec.md`

## Summary

Add an Ansible playbook to orchestrate the deployment of a 5-node K3s HA cluster (3 masters, 2 workers) using the existing `installer.sh` script. The playbook will handle retrieving the node token from the first master and securely passing it to the join nodes.

## Technical Context

**Language/Version**: Ansible (YAML), Bash

**Primary Dependencies**: `ansible-core` >= 2.12

**Storage**: N/A

**Testing**: Local VM tests / `ansible-playbook --syntax-check`

**Target Platform**: Ubuntu 22.04/24.04/26.04 or Debian 12/13 nodes

**Project Type**: Infrastructure as Code (Ansible Playbook)

**Performance Goals**: N/A (One-shot provisioning)

**Constraints**: Must use the existing `installer.sh` without requiring modifications to the script's core logic.

**Scale/Scope**: 5 nodes (3 control-plane, 2 worker)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Simplicity First**: The Ansible playbook must be simple to understand and run. It uses the `script` module to run `installer.sh` directly. (Pass)
- **II. Resiliency and Safety**: Ansible's sequential play execution ensures nodes are joined only after the first master is ready. (Pass)
- **III. Transparency**: Ansible provides standard STDOUT logging. (Pass)
- **IV. Standardized Networking**: Handled by `installer.sh`. (Pass)
- **V. Code Quality**: Playbook will use standard Ansible YAML format. (Pass)

## Project Structure

### Documentation (this feature)

```text
specs/001-ansible-homelab/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Inventory structure definition
├── quickstart.md        # How to run the Ansible playbook
├── contracts/           
│   └── inventory.example.yml # Sample inventory file
└── tasks.md             # Implementation tasks
```

### Source Code (repository root)

```text
ansible/
├── inventory.example.yml
└── deploy-k3s.yml       # Main playbook
```

**Structure Decision**: A new `ansible/` directory will be added to the repository to house the playbook and example inventory, keeping it separated from the main bash script.

## Complexity Tracking

*(No violations to justify)*
