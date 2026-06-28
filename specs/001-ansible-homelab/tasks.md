# Tasks: Ansible Homelab Support

**Input**: Design documents from `/specs/001-ansible-homelab/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create `ansible/` directory at the project root

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Create the example inventory file in `ansible/inventory.example.yml` based on `contracts/inventory.example.yml`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - One-Click HA Cluster Deployment (Priority: P1) 🎯 MVP

**Goal**: Provision an entire 5-node HA K3s cluster (3 masters, 2 workers) automatically via a single Ansible playbook.

**Independent Test**: Can be tested by running `ansible-playbook -i inventory.yml ansible/deploy-k3s.yml` against 5 fresh VMs and verifying `kubectl get nodes`.

### Implementation for User Story 1

- [x] T003 [US1] Create the main playbook file `ansible/deploy-k3s.yml`.
- [x] T004 [US1] Implement Play 1 in `ansible/deploy-k3s.yml` targeting `k3s_first_master` to execute `installer.sh --ha-first` and `slurp` the node token.
- [x] T005 [US1] Implement Play 2 in `ansible/deploy-k3s.yml` targeting `k3s_join_masters` to execute `installer.sh --ha-join` using the extracted token and master IP.
- [x] T006 [US1] Implement Play 3 in `ansible/deploy-k3s.yml` targeting `k3s_workers` to execute `installer.sh --worker` using the extracted token and master IP.

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T007 Update main `README.md` to reference the Ansible playbook and point to the Quickstart guide (`specs/001-ansible-homelab/quickstart.md`).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Parallel Opportunities

- The tasks are sequential and mostly involve single files (`deploy-k3s.yml`). Minimal parallelism is required since this is a small playbook implementation.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently against 5 local VMs.
5. Deploy/demo if ready

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Avoid: cross-story dependencies that break independence
