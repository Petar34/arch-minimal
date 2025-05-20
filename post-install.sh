#!/bin/bash

echo "[INFO] Pokrećem postavke unutar sistema..."

# 1. Dodaj korisnika petar
useradd -m -G wheel -s /bin/bash petar
echo "petar:lozinka" | chpasswd

# 2. Omogući sudo za grupu wheel
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# 3. Instaliraj osnovne pakete i okruženje
pacman -S --noconfirm \
  i3 xterm neovim git \
  networkmanager network-manager-applet \
  pipewire pipewire-pulse pavucontrol volumeicon \
  feh picom rofi thunar alacritty \
  ttf-ubuntu-font-family papirus-icon-theme htop \
  base-devel sudo flameshot \
  nvidia nvidia-utils gamemode \
  thunderbird

# 4. Omogući mrežu
systemctl enable NetworkManager

# 5. Postavi lokalizaciju i jezik
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
hwclock --systohc
sed -i 's/#hr_HR.UTF-8 UTF-8/hr_HR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=hr_HR.UTF-8" > /etc/locale.conf
echo "KEYMAP=hr" > /etc/vconsole.conf

# 6. Postavi hostname
echo "arch" > /etc/hostname

# 7. Instaliraj i konfiguriraj GRUB za EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# 8. Instaliraj yay (AUR helper)
su - petar -c 'git clone https://aur.archlinux.org/yay.git ~/yay'
su - petar -c 'cd ~/yay && makepkg -si --noconfirm'

# 9. Instaliraj AUR aplikacije (Chrome, Discord, Sidekick)
su - petar -c 'yay -S --noconfirm google-chrome discord sidekick-browser-bin'

# 10. Kloniraj i primijeni dotfiles
su - petar -c 'git clone https://github.com/Petar34/dotfiles ~/.dotfiles'
su - petar -c 'cp -r ~/.dotfiles/.config ~/'
su - petar -c 'cp ~/.dotfiles/.bashrc ~/'
su - petar -c 'cp ~/.dotfiles/.xinitrc ~/'

echo "[INFO] Post-install završen. Možeš sada izaći (exit) i pokrenuti reboot."

