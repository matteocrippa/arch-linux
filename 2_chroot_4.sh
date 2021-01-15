#!/bin/bash

# Env variables
. vars.sh

# Set different microcode, kernel params and initramfs modules according to CPU vendor
cpu_microcode="intel-ucode"
kernel_options=" i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2"
initramfs_modules="intel_agp i915"

arch-chroot /mnt /bin/bash <<EOF
echo "Set home key"
echo "$encrypt_key_file" > /root/.ssd_key
touch /etc/crypttab
echo "crypthome UUID=${PART_ID} /root/.ssd_key luks" > /etc/crypttab
EOF

#umount -R /mnt
#swapoff -a

echo "Arch Linux is ready. You can reboot now!"
