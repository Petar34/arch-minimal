#!/bin/bash
set -e

echo -e "\n\033[1;36m[INFO] Pokrećem postavke unutar sistema...\033[0m"

# 1. Dodaj korisnika admin
adduser --disabled-password --gecos "" admin
echo "admin:administrator" | chpasswd
usermod -aG sudo admin

# 2. Instaliraj osnovne pakete i okruženje
apt update
apt install -y xorg xinit i3 i3status i3lock rofi feh picom lxappearance \
  xterm neovim git thunar alacritty \
  network-manager network-manager-gnome \
  pipewire pipewire-audio pavucontrol volumeicon-alsa \
  fonts-dejavu papirus-icon-theme htop sudo flameshot curl unzip \
  thunderbird postgresql cmake make gcc

# 3. Omogući mrežu
systemctl enable NetworkManager
systemctl start NetworkManager

# 4. Lokalizacija
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
timedatectl set-local-rtc 0
locale-gen hr_HR.UTF-8 en_US.UTF-8
update-locale LANG=hr_HR.UTF-8
echo "KEYMAP=hr" > /etc/vconsole.conf

# 5. Hostname
echo "debian" > /etc/hostname

# 6. GRUB instalacija
grub-install /dev/nvme0n1 || true
update-grub || true

# 7. Dotfiles
su - admin -c 'git clone https://github.com/Petar34/dotfiles ~/.dotfiles || true'
su - admin -c 'cp -r ~/.dotfiles/.config ~/ || true'
su - admin -c 'cp ~/.dotfiles/.bashrc ~/ || true'
su - admin -c 'cp ~/.dotfiles/.xinitrc ~/ || true'

chown -R admin:admin /home/admin

# 8. Ollama (ako želiš AI lokalno)
curl -fsSL https://ollama.com/install.sh | sh || true

# 9. PostgreSQL baza
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'administrator';" || true
sudo -u postgres psql -c "CREATE DATABASE admin OWNER admin;" || true
PG_HBA="/etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf"
grep -q "127.0.0.1/32" "$PG_HBA" || echo "host    all             all             127.0.0.1/32            trust" >> "$PG_HBA"
grep -q "::1/128" "$PG_HBA" || echo "host    all             all             ::1/128                 trust" >> "$PG_HBA"
systemctl restart postgresql

# 10. user-manager CLI
cp /home/admin/.dotfiles/scripts/user-manager.sh /usr/local/bin/user-manager || true
chmod +x /usr/local/bin/user-manager

# 11. Autologin u tty1 (opcionalno)
echo '[ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && exec startx' >> /home/admin/.bash_profile
chown admin:admin /home/admin/.bash_profile

echo -e "\n\033[1;32m[ZAVRŠENO] Debian + i3 instalacija gotova. Pokreni reboot!\033[0m"
