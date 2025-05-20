#!/bin/bash

echo -e "\n\033[1;36m[INFO] Pokrećem postavke unutar sistema...\033[0m"

# 1. Dodaj korisnika admin
useradd -m -G wheel -s /bin/bash admin
echo "admin:administrator" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 2. Instaliraj osnovne pakete i okruženje
pacman -S --noconfirm \
  i3 xterm neovim git \
  networkmanager network-manager-applet \
  pipewire pipewire-pulse pavucontrol volumeicon \
  feh picom rofi thunar alacritty \
  ttf-ubuntu-font-family papirus-icon-theme htop \
  base-devel sudo flameshot \
  nvidia nvidia-utils gamemode \
  thunderbird postgresql cmake make gcc curl unzip

# 3. Omogući mrežu
systemctl enable NetworkManager

# 4. Lokalizacija
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
hwclock --systohc
sed -i 's/#hr_HR.UTF-8 UTF-8/hr_HR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=hr_HR.UTF-8" > /etc/locale.conf
echo "KEYMAP=hr" > /etc/vconsole.conf

# 5. Hostname
echo "arch" > /etc/hostname

# 6. GRUB EFI instalacija
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 7. Instalacija yay (ako nije već)
if ! command -v yay >/dev/null 2>&1; then
  su - admin -c 'git clone https://aur.archlinux.org/yay.git ~/yay'
  su - admin -c 'cd ~/yay && makepkg -si --noconfirm'
fi

# 8. Instaliraj AUR aplikacije
su - admin -c 'yay -S --noconfirm google-chrome discord sidekick-browser-bin python311'

# 9. Dotfiles
su - admin -c 'git clone https://github.com/Petar34/dotfiles ~/.dotfiles'
su - admin -c 'cp -r ~/.dotfiles/.config ~/ || true'
su - admin -c 'cp ~/.dotfiles/.bashrc ~/ || true'
su - admin -c 'cp ~/.dotfiles/.xinitrc ~/ || true'

# 10. Ollama (ne instalira model — ti ručno)
echo -e "\n[INFO] Instaliram Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 11. PostgreSQL setup
echo "[INFO] Postavljam PostgreSQL..."
sudo -u postgres initdb --locale=hr_HR.UTF-8 -D /var/lib/postgres/data
systemctl enable postgresql
systemctl start postgresql

# 12. Dodaj korisnika i bazu
sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'administrator';" || true
sudo -u postgres psql -c "CREATE DATABASE admin OWNER admin;" || true

# 13. Local trust auth (za dev)
PG_HBA="/var/lib/postgres/data/pg_hba.conf"
grep -q "127.0.0.1/32" "$PG_HBA" || echo "host    all             all             127.0.0.1/32            trust" >> "$PG_HBA"
grep -q "::1/128" "$PG_HBA" || echo "host    all             all             ::1/128                 trust" >> "$PG_HBA"
systemctl restart postgresql

# 14. Postavi user-manager CLI alat
echo "[INFO] Postavljam user-manager CLI alat..."
cp /home/admin/.dotfiles/scripts/user-manager.sh /usr/local/bin/user-manager || true
chmod +x /usr/local/bin/user-manager

echo -e "\n\033[1;32m[ZAVRŠENO] post-install.sh je uspješno izvršen. Spreman si za reboot!\033[0m"
