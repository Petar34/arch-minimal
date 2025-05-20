#!/bin/bash

echo -e "\033[1;36m[INFO] Pokreće se automatska instalacija Arch Linuxa...\033[0m"

# Provjeri internet vezu
ping -c 1 archlinux.org > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  echo "[GREŠKA] Nema internetske veze. Provjeri mrežu prije nastavka."
  exit 1
fi

# Prikaži dostupne diskove
echo -e "\nDostupni diskovi:"
lsblk -dpno NAME,SIZE | grep -v loop
echo ""

# Potvrda korisnika prije brisanja diska
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
echo "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI ZAUVIJEK."
read -p "Jesi li siguran da želiš nastaviti? (upiši 'da' za potvrdu): " potvrda
[[ $potvrda != "da" ]] && echo "[PREKID] Instalacija prekinuta." && exit 1

# POTPUNO brisanje svih tragova sa diska
wipefs -a "$DISK"
sgdisk --zap-all "$DISK"

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

# (Opcionalno) Swap file
fallocate -l 2G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# Instalacija base sistema + alati
pacstrap /mnt base linux linux-firmware grub sudo networkmanager neovim \
man-db man-pages base-devel

# Generiraj fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Postavi hostname
echo "admin" > /mnt/etc/hostname

# Postavi lokalizaciju
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Preuzmi post-install.sh
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
chmod +x /mnt/root/post-install.sh

# Pokreni post-install.sh u chrootu
arch-chroot /mnt /root/post-install.sh
