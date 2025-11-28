ssh admin@k3s-master.local << 'EOF'
sudo dd if=/dev/mmcblk0 of=/dev/nvme0n1 bs=4M status=progress conv=fsync
echo "DD complete, syncing disks..."
sleep 2
sudo sync
sleep 2
echo "Sync complete"
sudo poweroff
EOF
