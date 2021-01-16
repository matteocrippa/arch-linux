#!/bin/bash

# Env variables
. vars.sh

# Set different microcode, kernel params and initramfs modules according to CPU vendor
cpu_microcode="intel-ucode"
kernel_options=" i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2"
initramfs_modules="intel_agp i915"

echo "Updating system clock"
timedatectl set-ntp true

echo "Syncing packages database"
pacman -Sy --noconfirm

echo "Creating partition tables"
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk $NVME
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk $NVME

# echo "Zeroing partitions"
# cat /dev/zero > "$NVME"p1
# cat /dev/zero > "$NVME"p2

echo "Setting up cryptographic volume"
printf "%s" "$encryption_passphrase" | cryptsetup -h sha512 -s 512 --use-random --type luks2 luksFormat "$NVME"p2
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen "$NVME"p2 cryptlvm

echo "Creating physical volume"
pvcreate /dev/mapper/cryptlvm

echo "Creating volume volume"
vgcreate vg0 /dev/mapper/cryptlvm

echo "Creating logical volumes"
lvcreate -L +"$swap_size"GB vg0 -n swap
# lvcreate -l +100%FREE vg0 -n root

# echo "Setting up / partition"
# yes | mkfs.ext4 /dev/vg0/root
# mount /dev/vg0/root /mnt

# echo "Setting up /boot partition"
# yes | mkfs.fat -F32 "$NVME"p1
# mkdir /mnt/boot
# mount "$NVME"p1 /mnt/boot

# echo "Setting up swap"
# yes | mkswap /dev/vg0/swap
# swapon /dev/vg0/swap

# echo "Setting up home"
# mkdir /mnt/home
# mount /dev/vg1/home /mnt/home

# echo "Installing Arch Linux"
# yes '' | pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware lvm2 device-mapper e2fsprogs $cpu_microcode cryptsetup networkmanager wget man-db man-pages nano diffutils flatpak lm_sensors

# echo "Generating fstab"
# genfstab -U /mnt >> /mnt/etc/fstab

