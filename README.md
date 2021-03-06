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

- enable efi firmware editing `.vmx` and adding `firmware = 'efi'`
- lower swap size to 1GB

## Install script

- LVM on LUKS
- LUKS2
- systemd-boot (with Pacman hook for automatic updates)
- systemd init hooks (instead of busybox)
- SSD Periodic TRIM
- Intel/AMD microcode
- Standard Kernel + LTS kernel as fallback
- Hibernate support
- Kernel: LZ4 compression
- NMI watchdog disabled

### Requirements

- UEFI mode
- NVMe SSD
- TRIM compatible SSD
- CPU: Intel (Skylake or newer) / AMD
- GPU: AMDGPU - only if CPU vendor is AMD (this combination is hard-coded. For now, base script checks for CPU vendor and if it's AMD, then it'll also install required drivers for AMD GPU)

### Partitions

| Name                                                 | Type  | Mountpoint |
| ---------------------------------------------------- | :---: | :--------: |
| nvme0n1                                              | disk  |            |
| ├─nvme0n1p1                                          | part  |   /boot    |
| ├─nvme0n1p2                                          | part  |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                         | crypt |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─vg0-swap |  lvm  |   [SWAP]   |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─vg0-root |  lvm  |     /      |

## Post install script

- KDE / Gnome / Sway (separate scripts)
- UFW (deny incoming, allow outgoing)
- Automatic login
- Fonts
- Wallpapers
- Multilib
- yay (AUR helper)
- Plymouth
- Flatpak support
- Lutris with Wine support (commented)
- Syncthing
- Browsers:
  - Chromium: hardware acceleration enabled
  - Firefox: via Flatpak, with hardware acceleration enabled (see below: MISC - Firefox required configs for VA-API support)

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

### How to setup Github with SSH Key

```
git config --global user.email "Github external email"
git config --global user.name "Github username"
ssh-keygen -t rsa -b 4096 -C "Github email"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
copy SSH key and add to Github (eg. vim ~/.ssh/id_rsa.pub and copy content into github.com)
```

### How to install Lutris and Steam (Flatpak)

```
# Sources:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git
# https://github.com/GloriousEggroll/proton-ge-custom#flatpak
# https://github.com/flathub/net.lutris.Lutris

# Add Flatpak repos
flatpak remote-add --user --assumeyes --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --assumeyes --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install mesa-git
flatpak install --user --assumeyes flathub-beta org.freedesktop.Platform.GL.mesa-git//20.08 org.freedesktop.Platform.GL32.mesa-git//20.08

# Install Lutris
flatpak install --user --assumeyes flathub-beta net.lutris.Lutris//beta
flatpak install --user --assumeyes flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default

# Install Steam
flatpak install --user --assumeyes flathub com.valvesoftware.Steam

# Make Steam use mesa-git
sudo sed -i "s,Exec=,Exec=env FLATPAK_GL_DRIVERS=mesa-git ," /var/lib/flatpak/exports/share/applications/com.valvesoftware.Steam.desktop

# Download latest release from GloriousEggroll/proton-ge-custom and move it to Steam Flatpak
curl -Ls https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep -wo "https.*tar.gz" | wget -qi -
mkdir -p ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/
tar -xzf Proton-* -C ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/

# To enable proton ge: https://github.com/GloriousEggroll/proton-ge-custom#enabling

# Allow Steam Link through the Firewall
sudo ufw allow from 192.168.1.0/24 to any port 27036:27037 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 27031:27036 proto udp
```
