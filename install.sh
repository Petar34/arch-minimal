#!/bin/bash

echo -e "\033[1;36m[INFO] Pokreće se automatska instalacija Arch Linuxa...\033[0m"

lsblk
echo ""
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (da/ne): " potvrda
[[ $potvrda != "da" ]] && echo "Prekinuto." && exit 1

# Brisanje postojećih particija
sgdisk --zap-all "$DISK"

# Kreiranje particija
parted "$DISK" mklabel gpt
parted "$DISK" mkpart ESP fat32 1MiB 513MiB
parted "$DISK" set 1 esp on
parted "$DISK" mkpart primary ext4 513MiB 100%

# Formatiranje
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"

# Montiranje
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot
mount "${DISK}p1" /mnt/boot

# Swap (opcionalno)
fallocate -l 2G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
echo "/swapfile none swap defaults 0 0" >> /mnt/etc/fstab

# Instalacija sistema
pacstrap /mnt base linux linux-firmware grub sudo networkmanager neovim base-devel man-db man-pages

# Fstab
mkdir -p /mnt/etc
genfstab -U /mnt >> /mnt/etc/fstab

# Hostname i jezik
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Priprema mount točaka za chroot
mkdir -p /mnt/{proc,sys,dev,run,tmp}
chmod 1777 /mnt/tmp
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run

# Preuzimanje i pokretanje post-install skripte unutar chroota
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
chmod +x /mnt/root/post-install.sh
arch-chroot /mnt /root/post-install.sh
