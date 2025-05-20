#!/bin/bash

# Ovo je osnovni template. Dodaj potvrdu da korisnik zna što radi!
echo "[INFO] Pokreće se automatska instalacija Arch Linuxa."
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK

# Brisanje postojećih particija (oprez!)
sgdisk --zap-all $DISK

# Kreiranje particija: EFI + root
parted $DISK mklabel gpt
parted $DISK mkpart ESP fat32 1MiB 513MiB
parted $DISK set 1 esp on
parted $DISK mkpart primary ext4 513MiB 100%

# Formatiranje
mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2

# Montiranje
mount ${DISK}2 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot

# Instalacija base sistema
pacstrap /mnt base linux linux-firmware grub sudo networkmanager neovim
man-db man-pages base-devel

# Generiraj fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Kopiraj post-install u chroot
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
chmod +x /mnt/root/post-install.sh

# Chroot i pokreni postinstall
arch-chroot /mnt /root/post-install.sh
