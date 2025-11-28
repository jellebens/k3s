# Prepare

Download Raspberry Pi Imager from: https://www.raspberrypi.com/software/
Create SD Card: 
1. Raspberry Pi 5
2. Raspberry Pi OS (other)
3. Raspberry Pi OS Lite (64-bit)
4. Follow the rest of the steps

Boot from SD card

# Install 

## Clone SD Card to NVME
```bash
sudo dd if=/dev/mmcblk0 of=/dev/nvme0n1 bs=4M status=progress conv=fsync
sync
poweroff
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

## Set PCI gen 3
```bash
sudo raspi-config
```

Advanced Options > PCIe Speed > Click <Yes> > Click <Ok> > Click Finish

## Fix IP's

192.168.50.150


192.168.50.152
192.168.50.153
192.168.50.154
192.168.50.155

### Node 1

sudo nmcli con mod "netplan-wlan0-B3ns" ipv4.addresses 192.168.50.150/24
sudo nmcli con mod "netplan-wlan0-B3ns" ipv4.gateway 192.168.50.1
sudo nmcli con mod "netplan-wlan0-B3ns" ipv4.dns 192.168.50.144 192.168.50.145 192.168.50.1
sudo nmcli con mod "netplan-wlan0-B3ns" ipv4.method manual
sudo nmcli con up "netplan-wlan0-B3ns"


sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.50.151/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.50.1
sudo nmcli con mod "Wired connection 1" ipv4.dns 192.168.50.144,192.168.50.145,192.168.50.1
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"

### Node 2
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.50.152/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.50.1
sudo nmcli con mod "Wired connection 1" ipv4.dns 192.168.50.144,192.168.50.145,192.168.50.1"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"