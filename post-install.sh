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
  thunderbird postgresql cmake make gcc wget

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

# 6. GRUB instalacija (pretpostavlja /dev/nvme0n1)
grub-install /dev/nvme0n1 || true
update-grub || true

# 7. Instaliraj dodatne aplikacije (.deb)
echo -e "\n[INFO] Instaliram dodatne aplikacije (Chrome, Discord, Sidekick)..."

wget -qO chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./chrome.deb || true
rm chrome.deb

wget -qO discord.deb "https://discord.com/api/download?platform=linux&format=deb"
apt install -y ./discord.deb || true
rm discord.deb

wget -qO sidekick.deb "https://downloads.meetsidekick.com/browser/linux/deb"
apt install -y ./sidekick.deb || true
rm sidekick.deb

# 8. Dotfiles
su - admin -c 'git clone https://github.com/Petar34/dotfiles ~/.dotfiles || true'
su - admin -c 'cp -r ~/.dotfiles/.config ~/ || true'
su - admin -c 'cp ~/.dotfiles/.bashrc ~/ || true'
su - admin -c 'cp ~/.dotfiles/.xinitrc ~/ || echo "exec i3" > ~/.xinitrc'

chown -R admin:admin /home/admin

# 9. Ollama (opcionalno)
curl -fsSL https://ollama.com/install.sh | sh || true

# 10. PostgreSQL setup
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'administrator';" || true
sudo -u postgres psql -c "CREATE DATABASE admin OWNER admin;" || true

PG_HBA="/etc/postgresql/$(ls /etc/postgresql)/main/pg_hba.conf"
grep -q "127.0.0.1/32" "$PG_HBA" || echo "host    all             all             127.0.0.1/32            trust" >> "$PG_HBA"
grep -q "::1/128" "$PG_HBA" || echo "host    all             all             ::1/128                 trust" >> "$PG_HBA"
systemctl restart postgresql

# 11. user-manager CLI
cp /home/admin/.dotfiles/scripts/user-manager.sh /usr/local/bin/user-manager || true
chmod +x /usr/local/bin/user-manager

# 12. Automatski startx u TTY1
echo '[ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] && exec startx' >> /home/admin/.bash_profile
chown admin:admin /home/admin/.bash_profile

echo -e "\n\033[1;32m[ZAVRŠENO] post-install.sh za Debian + i3 je gotov. Pokreni reboot!\033[0m"
