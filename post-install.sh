#!/bin/bash
set -e

echo -e "\n\033[1;36m[INFO] Pokrećem postavke unutar sistema...\033[0m"

# 1. Dodaj korisnika admin
adduser --disabled-password --gecos "" admin
echo "admin:administrator" | chpasswd
usermod -aG sudo admin

# 2. Instaliraj osnovne pakete i okruženje
apt update
apt install -y i3 xterm neovim git \
  network-manager network-manager-gnome \
  pipewire pipewire-audio pavucontrol volumeicon \
  feh picom rofi thunar alacritty \
  fonts-ubuntu papirus-icon-theme htop \
  sudo flameshot curl unzip \
  thunderbird postgresql cmake make gcc

# 3. Omogući mrežu
systemctl enable NetworkManager

# 4. Lokalizacija
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
timedatectl set-local-rtc 0
locale-gen hr_HR.UTF-8 en_US.UTF-8
update-locale LANG=hr_HR.UTF-8
echo "KEYMAP=hr" > /etc/vconsole.conf

# 5. Hostname
echo "ubuntu" > /etc/hostname

# 6. GRUB instalacija (pretpostavlja EFI već radi)
grub-install
update-grub

# 7. APT ekvivalenti za AUR (ručna instalacija)
echo -e "\n[INFO] Instaliram dodatne aplikacije (Chrome, Discord, Sidekick)..."

# Google Chrome
wget -qO chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./chrome.deb || true
rm chrome.deb

# Discord
wget -qO discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt install -y ./discord.deb || true
rm discord.deb

# Sidekick (AUR-style, ako postoji .deb – prilagoditi ako je drugačije)
wget -qO sidekick.deb "https://downloads.meetsidekick.com/browser/linux/deb"
apt install -y ./sidekick.deb || true
rm sidekick.deb

# 8. Dotfiles
su - admin -c 'git clone https://github.com/Petar34/dotfiles ~/.dotfiles'
su - admin -c 'cp -r ~/.dotfiles/.config ~/ || true'
su - admin -c 'cp ~/.dotfiles/.bashrc ~/ || true'
su - admin -c 'cp ~/.dotfiles/.xinitrc ~/ || true'

# Ispravi vlasništvo (važno!)
chown -R admin:admin /home/admin/.bashrc
chown -R admin:admin /home/admin/.xinitrc
chown -R admin:admin /home/admin/.config

# 9. Ollama
echo "[INFO] Instaliram Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 10. PostgreSQL setup
echo "[INFO] Postavljam PostgreSQL..."
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'administrator';" || true
sudo -u postgres psql -c "CREATE DATABASE admin OWNER admin;" || true

# Trust autentikacija
PG_HBA="/etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf"
grep -q "127.0.0.1/32" "$PG_HBA" || echo "host    all             all             127.0.0.1/32            trust" >> "$PG_HBA"
grep -q "::1/128" "$PG_HBA" || echo "host    all             all             ::1/128                 trust" >> "$PG_HBA"
systemctl restart postgresql

# 11. user-manager CLI
echo "[INFO] Postavljam user-manager CLI alat..."
cp /home/admin/.dotfiles/scripts/user-manager.sh /usr/local/bin/user-manager || true
chmod +x /usr/local/bin/user-manager

echo -e "\n\033[1;32m[ZAVRŠENO] post-install.sh za Ubuntu je gotov. Pokreni reboot!\033[0m"
