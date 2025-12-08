# K3s Homelab Cluster - AI Coding Instructions

## Project Overview
This is an Ansible-based infrastructure-as-code project for provisioning and managing a Kubernetes (K3s) cluster on Raspberry Pi nodes. The project orchestrates networking configuration, K3s installation, and ArgoCD deployment across a multi-node cluster with separate master and worker nodes.

## Architecture & Key Components

### Role Structure
The codebase uses Ansible roles as the primary architectural boundary:

- **`roles/infra`** - Network configuration via NetworkManager. Applies static IPs, DNS, and gateway settings to all nodes before K3s installation. Tasks validate that required networking variables (`static_interface`, `static_ip`, `static_prefix`, `static_gateway`, `static_dns`) are defined per-host.

- **`roles/k3s`** - K3s cluster installation with node role separation:
  - `tasks/enable-cgroup.yml` - Configures cgroups on all nodes (prerequisite for K3s)
  - `tasks/install-master-nodes.yml` - Installs K3s master via curl script, polls for node-token, and fetches kubeconfig
  - `tasks/install-worker-nodes.yml` - (Implied) Installs worker nodes joining the cluster using the master's token

- **`roles/argocd`** - GitOps deployment (WIP). Playbook targets `hosts: masters` and uses Helm chart v9.1.4. Structure exists but main.yml is currently empty.

### Inventory Structure
**File**: `inventories/k3s-inventory.yaml`

- Single `k3s` group containing `masters` and `workers` subgroups
- Each host defines network variables (interface, IP, prefix, gateway, DNS servers)
- Master node: `k3s-node01.local` @ 192.168.50.151
- Worker nodes: `k3s-node02/03/04.local` @ 192.168.50.152-154
- Shared vars: K3s version (v1.34.1+k3s1), API endpoint, kubeconfig path

### Playbook Composition
- **`playbooks/k3s.yml`** - Main flow: applies `infra` role then `k3s` role to all k3s hosts
- **`playbooks/homelab.yml`** - Empty placeholder (likely reserved for additional homelab services)
- **`playbooks/argocd_install.yml`** - Targets masters only; defines ArgoCD Helm chart version and admin password variable
- **`playbooks/k3_uninstall.yml`** - Cleanup (implementation not shown)

## Critical Workflows

### Prerequisite Setup
Before running any playbook:

1. **Python venv with dependencies** (from `setup_python.sh`):
   ```bash
   python3 -m venv ~/.venvs/ansible
   source ~/.venvs/ansible/bin/activate
   pip install --upgrade pip
   pip install kubernetes passlib[bcrypt] openshift
   ```

2. **Ansible bootstrap** (if using Ubuntu nodes):
   ```bash
   sudo bash bootstrap-ansible.sh  # Installs Ansible + dependencies
   ```

3. **Run main playbook**:
   ```bash
   ANSIBLE_CONFIG=./ansible.cfg ansible-playbook playbooks/k3s.yml
   ```

### Networking Configuration
The infra role performs these operations in sequence:
1. Asserts all required `static_*` variables exist
2. Starts NetworkManager service
3. Queries NetworkManager for connection name using device name
4. Modifies connection with `nmcli` to set IPv4 (manual method), DNS, gateway
5. **Triggers node reboot** and waits for SSH to return
6. Displays resulting IP configuration

**Key detail**: Networking task will block and reboot the target node. The reboot task has 300s timeout and waits for SSH connectivity to confirm success.

### Node Installation Order
K3s installation follows this sequence:
1. Enable cgroups (all nodes)
2. Install master node(s) - curl installs K3s, polls for `/var/lib/rancher/k3s/server/node-token` with 30 retries (5 min window)
3. Read node token and set as fact
4. Fetch kubeconfig to controller
5. Install worker nodes (implied to use K3S_TOKEN and K3S_URL to join master)

## Conventions & Patterns

### Variable Hierarchy
- **Group vars**: Defined in inventory under `vars` blocks (e.g., `k3s.vars.version`, `k3s.vars.api`)
- **Host vars**: Per-node networking config in inventory (static_interface, static_ip, etc.)
- **Role defaults**: Would go in `roles/*/defaults/main.yml` (check these when extending roles)
- **Playbook vars**: Top-level like `argocd_chart_version` in `argocd_install.yml`

### Task Organization
- Tasks are split by functional concern: `enable-cgroup`, `install-master-nodes`, `install-worker-nodes` rather than role-level granularity
- Each file is imported with `import_tasks` and tagged for selective execution
- Tags available: `k3s`, `networking` - use `--tags k3s` to run only K3s tasks

### Privilege Escalation
- `become: true` is used in tasks requiring elevated privileges (e.g., k3s installation, cgroup config, networking changes)
- SSH is configured for `ansible_user: admin` with key-based auth (setup via `ssh-copy-id` in README)

### Error Handling
- Networking tasks validate preconditions with `ansible.builtin.assert`
- Node token wait uses `retries: 30, delay: 10` - **total 5-minute window** for K3s to start
- Reboot task has explicit `test_command: whoami` to validate SSH is live
- K3s master install uses `-o ConnectTimeout=10` equivalent via `reboot_timeout: 300`

## Adding New Features

### Extending the K3s Role
Example: Adding a new node configuration task:
1. Create `roles/k3s/tasks/my-feature.yml`
2. Import in `roles/k3s/tasks/main.yml`: `- import_tasks: my-feature.yml`
3. Add appropriate tag: `tags: [k3s]`
4. Define variables in inventory or `roles/k3s/defaults/main.yml`

### Adding Playbooks
New playbooks should:
- Follow the structure in `playbooks/k3s.yml` or `playbooks/argocd_install.yml`
- Reference roles by name (Ansible resolves via `ansible.cfg` roles_path)
- Use host groups from inventory (e.g., `hosts: masters`, `hosts: k3s`)
- Define required variables as playbook `vars` if not inventory-sourced

### Networking Customization
To add nodes:
1. Append to `inventories/k3s-inventory.yaml` under appropriate group (masters/workers)
2. Define all four networking vars: `static_interface`, `static_ip`, `static_prefix`, `static_gateway`, `static_dns`
3. If new nodes use different interface names, verify NetworkManager connection name with `nmcli con show`

## Common Gotchas

- **Kubeconfig path**: Defaults to `~/.kube/k3s.yaml` on controller; override via group var `kubeconfig_path`
- **K3s version**: Must match `version:` var in inventory; installer uses `INSTALL_K3S_VERSION` env var
- **Node token timing**: Master must write token file within 5 minutes; slow hardware may need `retries` increased
- **NetworkManager dependency**: Networking role requires NM running; will fail on systems using other network managers
- **Reboot safety**: Networking tasks reboot nodes; ensure SSH is working before running playbooks

## Testing & Validation

- **Dry-run**: `ansible-playbook playbooks/k3s.yml --check` (note: some tasks may still reboot in check mode)
- **Targeted execution**: `ansible-playbook -i inventories/k3s-inventory.yaml playbooks/k3s.yml --tags k3s`
- **Single node**: `ansible-playbook playbooks/k3s.yml -l k3s-node01.local`
- **Syntax check**: `ansible-playbook playbooks/k3s.yml --syntax-check`
