#!/bin/bash

# Env variables
. vars.sh

# Detect username
username=$(whoami)

# Install different packages according to GPU vendor (Intel, AMDGPU) 
gpu_drivers="vulkan-intel lib32-vulkan-intel intel-media-driver libvdpau-va-gl"
libva_environment_variable="export LIBVA_DRIVER_NAME=iHD"
vdpau_environment_variable="export VDPAU_DRIVER=va_gl"

echo "Adding multilib support"
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo "Syncing repos and updating packages"
sudo pacman -Syu --noconfirm

echo "Installing and configuring UFW"
sudo pacman -S --noconfirm ufw
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Installing GPU drivers"
sudo pacman -S --noconfirm mesa lib32-mesa $gpu_drivers vulkan-icd-loader lib32-vulkan-icd-loader

echo "Improving hardware video accelaration"
sudo pacman -S --noconfirm ffmpeg libva-utils libva-vdpau-driver vdpauinfo libva-intel-driver-hybrid

echo "Installing common applications"
sudo pacman -S --noconfirm git openssh links upower htop powertop p7zip ripgrep unzip fwupd exa x11-ssh-askpass neofetch

sudo pacman -S --noconfirm vmware-workspace open-vm-tools
sudo systemctl mask usbmuxd.service

echo "Adding Flathub repository (Flatpak)"
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update --appstream

echo "Installing Flatpak GTK breeze themes"
flatpak install --user --assumeyes org.gtk.Gtk3theme.Breeze
flatpak install --user --assumeyes org.gtk.Gtk3theme.Breeze-Dark

echo "Intalling Flatpaks"
flatpak install --user --assumeyes flathub org.mozilla.firefox
flatpak install --user --assumeyes flathub org.libreoffice.LibreOffice
flatpak install --user --assumeyes flathub org.filezillaproject.Filezilla
flatpak install --user --assumeyes flathub com.getpostman.Postman
flatpak install --user --assumeyes flathub org.videolan.VLC
flatpak install --user --assumeyes flathub org.kde.krita
flatpak install --user --assumeyes flathub com.google.AndroidStudio
flatpak install --user --assumeyes flathub com.visualstudio.code-oss
flatpak install --user --assumeyes flathub com.github.tchx84.Flatseal
flatpak install --user --assumeyes flathub org.keepassxc.KeePassXC
flatpak install --user --assumeyes flathub org.keepassxc.KeePassXC

echo "Improving font rendering issues with Firecpu_vendor=$(cat /proc/cpuinfo | grep vendor | uniq)
fox Flatpak"
sudo pacman -S --noconfirm gnome-settings-daemon
mkdir -p ~/.var/app/org.mozilla.firefox/config/fontconfig	
touch ~/.var/app/org.mozilla.firefox/config/fontconfig/fonts.conf	
tee -a ~/.var/app/org.mozilla.firefox/config/fontconfig/fonts.conf << EOF	
<?xml version='1.0'?>	
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>	
<fontconfig>	
    <!-- Disable bitmap fonts. -->	
    <selectfont><rejectfont><pattern>	
        <patelt name="scalable"><bool>false</bool></patelt>	
    </pattern></rejectfont></selectfont>	
</fontconfig>	
EOF

# echo "Installing chromium with GPU acceleration"
# sudo pacman -S --noconfirm chromium
# mkdir -p ~/.config/
# touch ~/.config/chromium-flags.conf
# tee -a ~/.config/chromium-flags.conf << EOF
# --ignore-gpu-blacklist
# --enable-gpu-rasterization
# --enable-zero-copy
# --enable-accelerated-video-decode
# --use-vulkan
# EOF

echo "Creating user's folders"
sudo pacman -S --noconfirm xdg-user-dirs

echo "Installing fonts"
sudo pacman -S --noconfirm ttf-roboto ttf-roboto-mono ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack noto-fonts ttf-fira-code ttf-fira-mono ttf-font-awesome noto-fonts-emoji ttf-hanazono adobe-source-code-pro-fonts ttf-cascadia-code

echo "Downloading wallpapers"
mkdir -p ~/Pictures/wallpapers
wget -P ~/Pictures/wallpapers/ "$repo_url"/wallpapers/wallpaper.jpg
wget -P ~/Pictures/wallpapers/ "$repo_url"/wallpapers/wallpaper2.jpg

echo "Installing yay"
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin

echo "Installing and configuring Plymouth"
yay -S --noconfirm plymouth-git
sudo sed -i 's/base systemd autodetect/base systemd sd-plymouth autodetect/g' /etc/mkinitcpio.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch-lts.conf
sudo mkinitcpio -p linux
sudo mkinitcpio -p linux-lts
sudo plymouth-set-default-theme -R bgrt
yay -S --noconfirm plymouth-theme-arch-logo-new

echo "Improving laptop battery"

echo "Installing and starting thermald"
yay -Sy acpi acpi_call tlp cpupower tp-battery-mode
sudo tee -a /etc/default/tlp << EOF
TLP_ENABLE=1

TLP_DEFAULT_MODE=AC

TLP_PERSISTENT_DEFAULT=0

DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2

MAX_LOST_WORK_SECS_ON_AC=15
MAX_LOST_WORK_SECS_ON_BAT=60

CPU_HWP_ON_AC=balance_performance
CPU_HWP_ON_BAT=balance_power


CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

SCHED_POWERSAVE_ON_AC=0
SCHED_POWERSAVE_ON_BAT=1

NMI_WATCHDOG=0

ENERGY_PERF_POLICY_ON_AC=balance-performance
ENERGY_PERF_POLICY_ON_BAT=power

DISK_DEVICES="nvme0n1 sda"

DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

SATA_LINKPWR_ON_AC="med_power_with_dipm max_performance"
SATA_LINKPWR_ON_BAT="med_power_with_dipm max_performance"

AHCI_RUNTIME_PM_TIMEOUT=15

INTEL_GPU_MIN_FREQ_ON_AC=600
INTEL_GPU_MIN_FREQ_ON_BAT=300
INTEL_GPU_MAX_FREQ_ON_AC=1000
INTEL_GPU_MAX_FREQ_ON_BAT=600
INTEL_GPU_BOOST_FREQ_ON_AC=1100
INTEL_GPU_BOOST_FREQ_ON_BAT=0

WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

WOL_DISABLE=Y

SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

SOUND_POWER_SAVE_CONTROLLER=Y

BAY_POWEROFF_ON_AC=0
BAY_POWEROFF_ON_BAT=0

BAY_DEVICE="sr0"

RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

USB_BLACKLIST_BTUSB=0
USB_BLACKLIST_PHONE=0
USB_BLACKLIST_PRINTER=1
USB_BLACKLIST_WWAN=0
RESTORE_DEVICE_STATE_ON_STARTUP=0

START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=95

START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=95

NATACPI_ENABLE=1
TPACPI_ENABLE=1
TPSMAPI_ENABLE=1
EOF
sudo systemctl enable --now tlp
sudo systemctl enable --now
yay -Sy throttled
sudo systemctl enable --now lenovo_fix.service
sudo systemctl mask thermald.service
yay -Sy low_battery_suspend

echo "Reducing VM writeback time"
sudo touch /etc/sysctl.d/dirty.conf
sudo tee -a /etc/sysctl.d/dirty.conf << EOF
vm.dirty_writeback_centisecs = 1500
EOF

echo "Setup Lenovo Keys"
sudo tee -a /etc/udev/hwdb.d/90-thinkpad-keyboard.hwdb << EOF
evdev:name:ThinkPad Extra Buttons:dmi:bvn*:bvr*:bd*:svnLENOVO*:pn*
 KEYBOARD_KEY_45=prog1
 KEYBOARD_KEY_49=prog2
EOF
sudo udevadm hwdb --update
sudo udevadm trigger --system-match="event*"
tee -a ~/.config/libinput-gestures.conf << EOF
gesture: swipe left 3 xdotool key super+ctrl+Right
gesture: swipe right 3 xdotool key super+ctrl+Left

gesture: pinch out 2     xdotool key ctrl+KP_Add
gesture: pinch in 2    xdotool key ctrl+KP_Subtract
EOF

echo "Setup printer"
yay -Sy sane brother-dcp1610w cups brscan4 simple-scan-git system-config-printer --needed --noconfirm
sudo brsaneconfig4 -a name="Brother" model="DCP1610W" ip=192.168.0.11
sudo systemctl enable --now org.cups.cupsd.service
sudo systemctl start org.cups.cupsd.service

echo "Setting environment variables (and improve Java applications font rendering)"
sudo tee -a /etc/environment << EOF
$libva_environment_variable
$vdpau_environment_variable
_JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=gasp'
JAVA_FONTS=/usr/share/fonts/TTF
EOF

echo "Disabling root (still allows sudo)"
passwd --lock root

echo "Installing pipewire multimedia framework"
sudo pacman -S --noconfirm pipewire libpipewire02

echo "Installing zsh"
sudo pacman -S --noconfirm zsh zsh-completions
chsh -s /usr/bin/zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Install Nvim"
yay -S --noconfirm neovim neovim-symlinks nodejs-neovim python2-neovim python-neovim 
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
yay -S --noconfirm the_silver_searcher

echo "Installing Node.js LTS"
yay -S --noconfirm nvm
echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.zshrc
nvm install --lts

echo "Git Setup"
git config --global core.editor "vim"
git config --global user.name "matteocrippa"
git config --global user.email "matteocrippa@users.noreply.github.com"

echo "Set environment variables and alias"
tee -a ~/.zshrc << EOF
## Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

## Plugins
plugins=(archlinux git systemd)

## Alias
alias upa="sudo rm -f /var/lib/pacman/db.lck && sudo pacman -Syu && yay -Syu --aur --devel && flatpak update && fwupdmgr refresh && fwupdmgr update"
alias gitu="git add . && git commit && git push"
alias ls="exa --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
EOF

echo "Flatpak Xdg"
yay -S --noconfirm flatpak-xdg-utils-git

echo "OBS studio"
yay -S --noconfirm obs-studio-wayland

echo "RClone"
mkdir ~/GoogleDrive
yay -S --noconfirm rclone