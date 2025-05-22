#!/bin/bash
set -e

USERNAME=admin

echo -e "\n\033[1;36m[INFO] Instalacija X servera, i3 i alata...\033[0m"
apt update
apt install -y xorg i3 i3status i3lock rofi feh picom lxappearance \
  network-manager-gnome xterm xinit

# Provjera postoji li home direktorij
if [ ! -d "/home/$USERNAME" ]; then
  echo "[GREŠKA] /home/$USERNAME ne postoji!"
  exit 1
fi

echo "[INFO] Postavljam .xinitrc za korisnika $USERNAME..."
echo "exec i3" > /home/$USERNAME/.xinitrc
chown "$USERNAME:$USERNAME" /home/$USERNAME/.xinitrc

echo "[INFO] Kreiram i3 konfiguraciju..."
mkdir -p /home/$USERNAME/.config/i3
cat <<EOF > /home/$USERNAME/.config/i3/config
exec --no-startup-id nm-applet
exec --no-startup-id picom
exec --no-startup-id feh --bg-scale /usr/share/pixmaps/debian-logo.png
exec --no-startup-id setxkbmap hr
EOF

chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/i3

echo -e "\n\033[1;32m[ZAVRŠENO] i3 i X su spremni! Prijavi se kao $USERNAME i pokreni: startx\033[0m"
