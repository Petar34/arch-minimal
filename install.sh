#!/bin/bash

set -e

echo -e "\033[1;36m[INFO] Osvježavam mirror listu...\033[0m"
pacman -Sy reflector --noconfirm
reflector --country "Germany,Croatia,Netherlands,Austria" --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

echo -e "\033[1;36m[INFO] Pokreće se automatska instalacija Arch Linuxa...\033[0m"

lsblk
echo ""
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (da/ne): " potvrda
[[ $potvrda != "da" ]] && echo "Prekinuto." && exit 1

# Brisanje i kreiranje particija
sgdisk --zap-all "$DISK"
parted "$DISK" mklabel gpt
parted "$DISK" mkpart ESP fat32 1MiB 513MiB
parted "$DISK" set 1 esp on
parted "$DISK" mkpart primary ext4 513MiB 100%

# Formatiranje
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"

# Montiranje
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}p1" /mnt/boot/efi

# Swap
fallocate -l 2G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile

# Instalacija paketa
pacstrap /mnt base linux linux-firmware grub efibootmgr sudo networkmanager neovim base-devel man-db man-pages curl git

# fstab
mkdir -p /mnt/etc
genfstab -U /mnt >> /mnt/etc/fstab

# Lokalizacija
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "hr_HR.UTF-8 UTF-8" >> /mnt/etc/locale.gen

# Mountanje potrebnih datotečnih sustava
for dir in proc sys dev run tmp; do
    mkdir -p /mnt/$dir
done
chmod 1777 /mnt/tmp
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys && mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev && mount --make-rslave /mnt/dev
mount --bind /run /mnt/run

# Preuzimanje skripti
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
curl -o /mnt/root/post-i3.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-i3.sh
chmod +x /mnt/root/post-install.sh /mnt/root/post-i3.sh

# Chroot i pokretanje postavki
arch-chroot /mnt /root/post-install.sh
arch-chroot /mnt /root/post-i3.sh

echo -e "\n\033[1;32m[INFO] Instalacija završena! Pokreni reboot.\033[0m"
