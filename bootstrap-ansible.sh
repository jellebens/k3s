#!/usr/bin/env bash
#
# Ansible bootstrap script for Ubuntu 20.04/22.04/24.04
# - Adds official Ansible PPA
# - Installs Ansible + common extras

set -euo pipefail

# Color codes
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

LOG_PREFIX="${GREEN}[ansible-bootstrap]${RESET}"
ERR_PREFIX="${RED}[ansible-bootstrap] ERROR${RESET}"

info()  { echo -e "${LOG_PREFIX} $*"; }
error() { echo -e "${ERR_PREFIX} $*" >&2; }

# 1. Basic checks
if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root. Use: sudo $0"
  exit 1
fi

if ! command -v lsb_release >/dev/null 2>&1; then
  info "Installing lsb-release..."
  apt-get update -y
  apt-get install -y lsb-release
fi

UBUNTU_CODENAME=$(lsb_release -cs || echo "unknown")
UBUNTU_DESC=$(lsb_release -ds || echo "Ubuntu")

info "Detected OS: ${UBUNTU_DESC} (${UBUNTU_CODENAME})"

# 2. Update APT and install base dependencies
info "Updating package index..."
apt-get update -y

info "Installing base dependencies..."
apt-get install -y \
  software-properties-common \
  python3 \
  python3-pip \
  python3-venv \
  sshpass \
  python3-paramiko \
  python3-jmespath \
  ca-certificates \
  curl

# 3. Add Ansible PPA
if ! grep -R "ppa.launchpadcontent.net/ansible" /etc/apt/ 2>/dev/null | grep -q ansible; then
  info "Adding Ansible PPA..."
  add-apt-repository --yes --update ppa:ansible/ansible
else
  info "Ansible PPA already present, skipping..."
fi

# 4. Install Ansible
info "Installing Ansible..."
apt-get update -y
apt-get install -y ansible

# 5. Show version and basic info
info "Ansible installation complete."
info "Ansible version:"
ansible --version || error "Ansible not found in PATH (unexpected)."


# Fancy success banner
SUCCESS_COLOR="\e[92m"
RESET="\e[0m"

echo -e "${SUCCESS_COLOR}"
echo "       _     __  __    _    ____    ___  _  __  "
echo "      / \   |  \/  |  / \  |  _ \  / _ \ | |/ /  "
echo "     / _ \  | |\/| | / _ \ | |_)  | | | || ' /   "
echo "    / ___ \ | |  | |/ ___ \|  _ < | |_| || . \   "
echo "   /_/   \_\|_|  |_/_/   \_\_| \_\ \___/ |_|\_\  "
echo "        A M A R O K   C O N S U L T I N G       "
echo ""
echo " 🎉 Ansible installation completed successfully! 🎉"
echo "  You can now use 'ansible' and 'ansible-playbook'. "
echo -e "${RESET}"
