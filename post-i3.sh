#!/bin/bash
set -e

USERNAME=admin

echo -e "\n\033[1;36m[INFO] Instalacija X servera, i3 i alata...\033[0m"
apt update
apt install -y xorg i3 i3status i3lock rofi feh picom lxappearance \
  network-manager-gnome xterm xinit volumeicon

# Provjera postoji li home direktorij
if [ ! -d "/home/$USERNAME" ]; then
  echo "[GREŠKA] /home/$USERNAME ne postoji!"
  exit 1
fi

echo "[INFO] Postavljam .xinitrc za korisnika $USERNAME..."
cat <<EOF > /home/$USERNAME/.xinitrc
#!/bin/bash

setxkbmap hr

if [ -f "\$HOME/Pictures/wallpaper.jpg" ]; then
    feh --bg-scale "\$HOME/Pictures/wallpaper.jpg" &
fi

command -v nm-applet >/dev/null && nm-applet &
command -v volumeicon >/dev/null && volumeicon &

exec i3
EOF

chmod +x /home/$USERNAME/.xinitrc
chown "$USERNAME:$USERNAME" /home/$USERNAME/.xinitrc

echo "[INFO] Dodajem automatski startx u .bash_profile..."
echo '[ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ] && exec startx' >> /home/$USERNAME/.bash_profile
chown "$USERNAME:$USERNAME" /home/$USERNAME/.bash_profile

echo -e "\n\033[1;32m[ZAVRŠENO] i3 i X su spremni! Prijavi se kao $USERNAME i i3 će se pokrenuti automatski.\033[0m"
