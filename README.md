# Arch Linux install scripts

## Install

```bash
pacman -Sy git
git clone https://github.com/matteocrippa/arch-linux.git
```

Then edit `vars.sh` according to your setup.

```bash
vim vars.sh
```

If testing on vmware you need to:

- add in vmware a NVME disk
- enable efi firmware editing `.vmx` and adding `firmware = "efi"`
- lower swap size to 1GB

### Partitions

| Name                                                 | Type  | Mountpoint |
| ---------------------------------------------------- | :---: | :--------: |
| nvme0n1                                              | disk  |            |
| ├─nvme0n1p1                                          | part  |   /boot    |
| ├─nvme0n1p2                                          | part  |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                         | crypt |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─vg0-swap |  lvm  |   [SWAP]   |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─vg0-root |  lvm  |     /      |
| sda                                                  | disk  |            |
| ├─sda1                                               | part  |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                         | crypt |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─vg1-home |  lvm  |     /home  |

## Installation guide

1. Download and boot into the latest [Arch Linux iso](https://www.archlinux.org/download/)
2. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
3. Clear all existing partitions (see below: MISC - How to clear all partitions)
4. Give highest priority to the closest mirror to you on /etc/pacman.d/mirrorlist by moving it to the top
5. Sync repos: `pacman -Sy` and install wget `pacman -S wget`
6. `wget https://raw.githubusercontent.com/exah-io/arch-linux/master/1_install.sh`
7. Change the variables at the top of the file (lines 3 through 9)
   - continent_country must have the following format: Zone/SubZone . e.g. Europe/Berlin
   - run `timedatectl list-timezones` to see full list of zones and subzones
8. Make the script executable: `chmod +x 1_install.sh`
9. Run the script: `./1_install.sh`
10. Reboot into Arch Linux
11. Connect to wifi with `nmtui`
12. `wget https://raw.githubusercontent.com/exah-io/arch-linux/master/2_gnome.sh` or `2_plasma.sh` or `2_sway.sh`
13. Make the script executable: `chmod +x 2_gnome.sh` or `chmod +x 2_plasma.sh` or `chmod +x 2_sway.sh`
14. Run the script: `./2_gnome.sh` or `./2_plasma.sh` or `./2_sway.sh`

## Misc guides

### How to clear all partitions

```
gdisk /dev/nvme0n1
x
z
y
y
```

### Firefox required configs for VA-API support

- Run `sudo flatpak override --socket=wayland --env="MOZ_ENABLE_WAYLAND=1 GTK_USE_PORTAL=1" org.mozilla.firefox`
- At about:config set `gfx.webrender.enabled` and `widget.wayland-dmabuf-vaapi.enabled` to true and restart browser
  - Read original blog post [here](https://mastransky.wordpress.com/2020/06/03/firefox-on-fedora-finally-gets-va-api-on-wayland/)
  - Note: base script already sets the required environment variables. Only changing these 2 configs suffices

### How to enable secure boot

1. Download [sbctl-git](https://aur.archlinux.org/packages/sbctl-git/)
2. Confirm secure boot is disabled and delete existing keys in the bios (should automatically go into setup mode)
3. Confirm status (setup mode): `sudo sbctl status`
4. Create new keys: `sudo sbctl create-keys`
5. Enroll new keys: `sudo sbctl enroll-keys`
6. Confirm status (setup mode should now be disabled): `sudo sbctl status`
7. Confirm what needs to be signed: `sudo sbctl verify`
8. Sign with new keys:

- `sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI`
- `sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi`
- `sudo sbctl sign -s /boot/vmlinuz-linux`
- `sudo sbctl sign -s /boot/vmlinuz-linux-lts`
- `sudo sbctl sign -s /usr/lib/fwupd/efi/fwupdx64.efi -o /usr/lib/fwupd/efi/fwupdx64.efi.signed`

9. Reboot and enable secure boot in the bios
10. Confirm status (secure boot enabled): `sudo sbctl status`

### How to chroot

```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm
mount /dev/vg0/root /mnt
arch-chroot /mnt
```
