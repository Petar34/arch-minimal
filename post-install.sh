#!/bin/bash

echo "[INFO] Pokrećem postavke unutar sistema..."

# Dodaj korisnika petar
useradd -m -G wheel -s /bin/bash petar
echo "petar:lozinka" | chpasswd

# Omogući sudo za grupu wheel
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Instaliraj korisne alate i minimalistički desktop
pacman -S --noconfirm i3 xterm firefox neovim git network-manager-applet gamemode steam

# Omogući mrežu
systemctl enable NetworkManager

# Postavi lokalizaciju
ln -sf /usr/share/zoneinfo/Europe/Zagreb /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "arch" > /etc/hostname

# Instaliraj GRUB na EFI
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# (opcionalno) Kloniraj tvoje dotfiles
# su - petar -c 'git clone https://github.com/Petar34/dotfiles ~/.config'

echo "[INFO] Post-install završen. Možeš sada izaći i rebootati."
