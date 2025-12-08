# Prepare Raspberry Pi

Download Raspberry Pi Imager from: https://www.raspberrypi.com/software/
Create SD Card: 
1. Raspberry Pi 5
2. Raspberry Pi OS (other)
3. Raspberry Pi OS Lite (64-bit)
4. Follow the rest of the steps

Boot from SD card

## Install 

## Clone SD Card to NVME
```bash
sudo dd if=/dev/mmcblk0 of=/dev/nvme0n1 bs=4M status=progress conv=fsync
sudo sync
sudo poweroff
```
Remove SD Card

Boot from NVME

## Change hostname
```bash
sudo hostnamectl set-hostname newhostname
```

## Expand FS
```bash
sudo raspi-config --expand-rootfs
```

## Setup ssh
```bash
ssh-keygen

ssh-copy-id admin@<raspberry pi>
```

## Set PCI gen 3 (optional)
```bash
sudo raspi-config
```

Advanced Options > PCIe Speed > Click <Yes> > Click <Ok> > Click Finish

# Ansible

## Install 

```bash
sudo apt update
sudo apt install -y software-properties-common

sudo add-apt-repository --yes --update ppa:ansible/ansible

sudo apt install -y ansible

```

## Activate Virtual Environment
```bash
source ~/.venvs/ansible/bin/activate
```

## Install Collections
```bash
ansible-galaxy collection install ansible.posix
```
## Store secrets
```bash
ansible-vault create host_vars/k3s-master01.local.yml
```

Your editor opens, put the following in the file:
```bash
ansible_user: admin
ansible_password: "SuperSecretMasterPwd"
```
Save and quit


## Run playbook
```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook playbooks/k3s.yaml

ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i ./inventories/homelab-inventory.yaml ./playbooks/bootstrap-ssh.yml --vault-password-file ~/.ansible-vault-pass
```