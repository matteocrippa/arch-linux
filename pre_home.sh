#!/bin/bash

# Env variables
. vars.sh

echo "Creating home partition tables"
printf "o\ny\nn\n1\n\n\n8e00\nw\ny\n" | gdisk $SSD

echo "Generate key"
dd if=/dev/urandom of=.ssd_key bs=1024 count=20

echo "Setting up cryptographic volume"
printf "%s" "$encryption_passphares_home" | cryptsetup -h sha512 -s 512 --use-random --type luks2 luksFormat "$SSD"1
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen "$SSD"1 crypthome
printf "%s" "$encryption_passphares_home" | cryptsetup luksAddKey "$SSD"1 .ssd_key

echo "Creating physical volume"
pvcreate /dev/mapper/crypthome

echo "Creating volume volume"
vgcreate vg1 /dev/mapper/crypthome

echo "Creating logical volumes"
lvcreate -l +100%FREE vg1 -n home

echo "Setting up home partition"
yes | mkfs.ext4 /dev/vg1/home
mkdir /mnt/home
mount /dev/vg1/home /mnt/home