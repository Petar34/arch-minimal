#!/bin/bash

echo "[INFO] Pokreće se automatska instalacija Arch Linuxa."

# Potvrda korisnika prije brisanja diska
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (y/n): " potvrda
[[ $potvrda != "y" ]] && echo "Prekinuto." && exit 1

# Brisanje postojećih particija
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

# Instalacija base sistema + dodatni alati
pacstrap /mnt base linux linux-firmware grub sudo networkmanager neovim \
man-db man-pages base-devel

# Generiraj fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Postavi hostname (možeš slobodno promijeniti ime)
echo "petar" > /mnt/etc/hostname

# Postavi lokalizaciju (hrvatski jezik i vremenska zona)
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Kopiraj post-install u chroot
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
chmod +x /mnt/root/post-install.sh

# Chroot i pokreni postinstall
arch-chroot /mnt /root/post-install.sh
