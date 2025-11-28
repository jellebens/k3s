#!/usr/bin/env bash
set -euo pipefail

name="${1:-}"

if [[ -z "$name" ]]; then
  echo "Usage: $0 {k3s-node01|k3s-node02|k3s-node03|k3s-node04|k3s-node05}"
  exit 1
fi

ip=""
case "$name" in
  k3s-node01)
    ip="192.168.50.151/24"
    ;;
  k3s-node02)
    ip="192.168.50.152/24"
    ;;
  k3s-node03)
    ip="192.168.50.153/24"
    ;;
  k3s-node04)
    ip="192.168.50.154/24"
    ;;
  k3s-node05)
    ip="192.168.50.155/24"
    ;;
  *)
    echo "Usage: $0 {k3s-node01|k3s-node02|k3s-node03|k3s-node04|k3s-node05}"
    exit 1
    ;;
esac

ssh "admin@${name}.local" <<EOF
echo "Configuring static IP addresses..."

echo "Setting IP to $ip"
sudo nmcli con mod "Wired connection 1" ipv4.addresses "$ip"
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.50.1
sudo nmcli con mod "Wired connection 1" ipv4.dns "192.168.50.144 192.168.50.145 192.168.50.1"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo reboot
EOF

