#!/bin/bash

set -e

echo -e "\n\033[1;36m[INFO] Pokreće se automatska instalacija Arch Linuxa...\033[0m\n"

# Provjera mreže
ping -c 1 archlinux.org > /dev/null 2>&1 || {
  echo "[GREŠKA] Nema interneta. Provjeri mrežu prije nastavka."
  exit 1
}

# Prikaži diskove
echo "Dostupni diskovi:"
lsblk -dno NAME,SIZE | grep -v loop
echo ""

read -p "Upiši naziv diska (npr. /dev/nvme0n1): " DISK

# Spriječi korištenje USB sticka
if [[ "$DISK" == "/dev/sd"* ]]; then
  echo "[GREŠKA] Ne smiješ instalirati na USB stick ($DISK)."
  exit 1
fi

# Potvrda brisanja
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (da/ne): " potvrda
[[ "$potvrda" != "da" ]] && echo "Prekinuto." && exit 1

# Obriši sve i kreiraj particije
wipefs -a "$DISK"
sgdisk --zap-all "$DISK"
parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart ESP fat32 1MiB 513MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary ext4 513MiB 100%

EFI="${DISK}p1"
ROOT="${DISK}p2"

mkfs.fat -F32 "$EFI"
mkfs.ext4 "$ROOT"

mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

# Provjera montaže i slobodnog prostora
df -h /mnt | grep -q "/mnt" || {
  echo "[GREŠKA] Nešto nije u redu s montiranjem /mnt."
  exit 1
}

AVAIL=$(df /mnt | awk 'NR==2 {print $4}')
if [[ "$AVAIL" -lt 1500000 ]]; then
  echo "[GREŠKA] Nedovoljno prostora na /mnt ($AVAIL KB)."
  exit 1
fi

# Swap file
fallocate -l 2G /mnt/swapfile || echo "[INFO] Preskočen swap (nije kritično)"
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile && swapon /mnt/swapfile
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# Instalacija sistema
pacstrap /mnt base linux linux-firmware grub sudo networkmanager neovim \
man-db man-pages base-devel > /mnt/install.log

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Hostname i lokalizacija
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Preuzmi post-install
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
chmod +x /mnt/root/post-install.sh

# Pokreni
arch-chroot /mnt /root/post-install.sh || {
  echo "[GREŠKA] Nešto je pošlo po zlu u post-install fazi."
  echo "Provjeri /mnt/install.log za detalje."
}

echo -e "\n\033[1;32m[ZAVRŠENO] Instalacija je uspješna! Možeš rebootati.\033[0m"
