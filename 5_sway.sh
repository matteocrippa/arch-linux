#!/bin/bash

# Env variables
. vars.sh

echo "Installing sway and additional packages"
sudo pacman -S --noconfirm sway swaylock swayidle waybar rofi light pulseaudio pavucontrol slurp grim ristretto tumbler mousepad

echo "Ricing sway"
mkdir -p ~/.config/sway
wget -P ~/.config/sway/ "$repo_url"/dotfiles/sway/config

echo "Ricing waybar"
mkdir -p ~/.config/waybar
wget -P ~/.config/waybar/ "$repo_url"/dotfiles/waybar/config
wget -P ~/.config/waybar/ "$repo_url"/dotfiles/waybar/style.css
mkdir -p ~/.config/script
wget -P ~/.config/waybar/script/ "$repo_url"/dotfiles/waybar/script/wbm_battery0
wget -P ~/.config/waybar/script/ "$repo_url"/dotfiles/waybar/script/wbm_battery1
chmod +x ~/.config/waybar/script/wbm_battery0 ~/.config/waybar/script/wbm_battery1

echo "Ricing rofi"
mkdir -p ~/.config/rofi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/config.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/base16-one-light.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/base16-onedark.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-common.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-dark-hard.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-dark-soft.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-dark.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-light-hard.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-light-soft.rasi
wget -P ~/.config/rofi/ "$repo_url"/dotfiles/rofi/gruvbox-light.rasi

echo "Enabling sway autostart"
touch ~/.zprofile
tee -a ~/.zprofile << EOF
if [[ -z \$DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    export LIBVA_DRIVER_NAME=i965
    export CLUTTER_BACKEND=wayland
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export QT_WAYLAND_FORCE_DPI=physical
    export ECORE_EVAS_EVAS_ENGINE=wayland_egl
    export ELM_ENGINE=wayland_egl
    export SDL_VIDEODRIVER=wayland
    export _JAVA_AWT_WM_NONREPARENTING=1
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_DBUS_REMOTE=1
    export QT_ENABLE_HIGHDPI_SCALING=0
    export QT_QPA_PLATFORM=xcb
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export CLUTTER_BACKEND=wayland
    export ECORE_EVAS_ENGINE=wayland_egl
    export ELM_ENGINE=wayland_wgl
    export SDL_VIDEODRIVER=wayland
    XKB_DEFAULT_LAYOUT=us exec sway
fi
EOF

echo "Installing and ricing Alacritty terminal"
sudo pacman -S --noconfirm alacritty
mkdir -p ~/.config/alacritty/
wget -P ~/.config/alacritty/ "$repo_url"/dotfiles/alacritty/alacritty.yml

echo "Installing thunar with auto-mount and archives creation/deflation support"
sudo pacman -S --noconfirm thunar gvfs thunar-volman thunar-archive-plugin ark file-roller xarchiver

echo "Installing PDF viewer"
sudo pacman -S --noconfirm xreader

echo "Changing GTK and icons themes"
sudo pacman -S --noconfirm lxappearance

mkdir -p ~/.themes
wget -P ~/.themes "$repo_url"/themes-icons/Orchis-light.tar.xz
tar -xf ~/.themes/Orchis-light.tar.xz -C ~/.themes
rm -f ~/.themes/Orchis-light.tar.xz

mkdir -p ~/.local/share/icons/
wget -P ~/.local/share/icons/ "$repo_url"/themes-icons/01-Tela.tar.xz
tar -xf ~/.themes/01-Tela.tar.xz -C ~/.local/share/icons/
rm -f ~/.local/share/icons/01-Tela.tar.xz

wget -P ~/.config/ "$repo_url"/dotfiles/gtk/.gtkrc-2.0

mkdir -p ~/.config/gtk-3.0/
wget -P ~/.config/gtk-3.0/ "$repo_url"/dotfiles/gtk/gtk-3.0/settings.ini

mkdir -p ~/.icons/default/
wget -P ~/.icons/default/ "$repo_url"/dotfiles/gtk/index.theme

echo "Enabling autologin"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo touch /etc/systemd/system/getty@tty1.service.d/override.conf
sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $USER --noclear %I $TERM
END

echo "Removing last login message"
touch ~/.hushlogin

echo "Installing xwayland"
sudo pacman -S --noconfirm xorg-server-xwayland

echo "Installing wdisplays"
yay -S --noconfirm wdisplays-git lxsession

echo "Setting some default applications"
xdg-mime default ristretto.desktop image/jpeg
xdg-mime default ristretto.desktop image/jpg
xdg-mime default ristretto.desktop image/png
xdg-settings set default-web-browser firefox.desktop

echo "Creating screenshots folder"
mkdir -p ~/Pictures/screenshots

echo "Cleanup"
yay -Ycc --noconfirm