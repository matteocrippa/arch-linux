#!/bin/bash

# Env variables
. vars.sh

# Set different microcode, kernel params and initramfs modules according to CPU vendor
cpu_microcode="intel-ucode"
kernel_options=" i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2"
initramfs_modules="intel_agp i915"

echo "Configuring new system"

arch-chroot /mnt /bin/bash <<EOF
echo "Setting system clock"
ln -sf /usr/share/zoneinfo/$continent_city /etc/localtime
hwclock --systohc --localtime

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hostname"
echo $hostname > /etc/hostname

echo "Setting root password"
echo -en "$root_password\n$root_password" | passwd

echo "Creating new user"
useradd -m -G wheel -s /bin/bash $username
usermod -a -G video $username
echo -en "$user_password\n$user_password" | passwd $username

echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 $initramfs_modules)/' /etc/mkinitcpio.conf
sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
mkinitcpio -p linux-lts

echo "Setting up systemd-boot"
bootctl --path=/boot install
EOF

arch-chroot /mnt /bin/bash <<EOF
mkdir -p /boot/loader/
echo ' ' > /boot/loader/loader.conf
tee -a /boot/loader/loader.conf << END
default arch.conf
timeout 2
editor 0
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$cpu_microcode.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value "$NVME"p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
END

touch /boot/loader/entries/arch-lts.conf
tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_microcode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value "$NVME"p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
END

echo "Updating systemd-boot"
bootctl --path=/boot update

echo "Setting up Pacman hook for automatic systemd-boot updates"
mkdir -p /etc/pacman.d/hooks/
touch /etc/pacman.d/hooks/systemd-boot.hook
tee -a /etc/pacman.d/hooks/systemd-boot.hook << END
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
END
EOF

arch-chroot /mnt /bin/bash <<EOF
echo "Enabling periodic TRIM"
systemctl enable fstrim.timer

echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
EOF

arch-chroot /mnt /bin/bash <<EOF
echo "Set home key"
echo "$encrypt_key_file" > /root/.ssd_key
touch /etc/crypttab
echo "crypthome UUID=${PART_ID} /root/.ssd_key luks" > /etc/crypttab
EOF

#umount -R /mnt
#swapoff -a

echo "Arch Linux is ready. You can reboot now!"
