#!/bin/bash
# metasploitable2-setup.sh
# Script to set up Metasploitable2 VM in VirtualBox on Linux
# Usage: ./metasploitable2-setup.sh /path/to/Metasploitable.vmdk

set -e

VM_NAME="Metasploitable2"
VMDK_PATH="$1"

if [ -z "$VMDK_PATH" ]; then
    echo "Usage: $0 /path/to/Metasploitable.vmdk"
    exit 1
fi

if [ ! -f "$VMDK_PATH" ]; then
    echo "Error: File $VMDK_PATH not found!"
    exit 1
fi

echo "[*] Checking if host-only network vboxnet0 exists..."
if ! VBoxManage list hostonlyifs | grep -q "vboxnet0"; then
    echo "[*] Creating host-only network vboxnet0..."
    sudo VBoxManage hostonlyif create
    sudo VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
    sudo VBoxManage dhcpserver add --ifname vboxnet0 \
        --server-ip 192.168.56.1 --netmask 255.255.255.0 \
        --lower-ip 192.168.56.100 --upper-ip 192.168.56.254 --enable
else
    echo "[*] vboxnet0 already exists, skipping..."
fi

echo "[*] Removing any existing VM named $VM_NAME..."
VBoxManage unregistervm "$VM_NAME" --delete || true

echo "[*] Creating new VM $VM_NAME..."
VBoxManage createvm --name "$VM_NAME" --ostype "Ubuntu" --register
VBoxManage modifyvm "$VM_NAME" --memory 512 --cpus 1 --ioapic on
VBoxManage modifyvm "$VM_NAME" --nic1 hostonly --hostonlyadapter1 vboxnet0

echo "[*] Adding IDE Controller..."
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide

echo "[*] Attaching Metasploitable2 disk..."
VBoxManage storageattach "$VM_NAME" \
    --storagectl "IDE Controller" --port 0 --device 0 --type hdd \
    --medium "$VMDK_PATH"

echo "[*] Setup complete! To start the VM, run:"
echo "    VBoxManage startvm \"$VM_NAME\" --type gui"
