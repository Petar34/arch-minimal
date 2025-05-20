#!/bin/bash
set -e

USERNAME=admin

echo "[*] Instalacija X servera, i3 i alata..."
pacman -Sy --noconfirm xorg xorg-xinit i3-wm i3status i3lock \
  rofi feh picom lxappearance network-manager-applet xterm

echo "[*] Postavljanje .xinitrc za korisnika $USERNAME..."
echo "exec i3" > /home/$USERNAME/.xinitrc
chown $USERNAME:$USERNAME /home/$USERNAME/.xinitrc

echo "[*] Kreiranje osnovnog i3 config-a..."
mkdir -p /home/$USERNAME/.config/i3
cat <<EOF > /home/$USERNAME/.config/i3/config
exec --no-startup-id nm-applet
exec --no-startup-id picom
exec --no-startup-id feh --bg-scale /usr/share/backgrounds/archlinux/arch-wallpaper.jpg
exec --no-startup-id setxkbmap hr
EOF

chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/i3

echo "[+] i3 i X spremni. Prijavi se kao $USERNAME i pokreni: startx"
