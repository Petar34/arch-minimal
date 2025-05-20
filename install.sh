#!/bin/bash

set -e

echo -e "\033[1;36m[INFO] Pokreće se automatska instalacija Ubuntu Server 24.04...\033[0m"

lsblk
echo ""
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (da/ne): " potvrda
[[ $potvrda != "da" ]] && echo "Prekinuto." && exit 1

# Brisanje i priprema diska
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

# Bootstrap minimalne instalacije (Ubuntu base system)
debootstrap noble /mnt http://archive.ubuntu.com/ubuntu/

# Mountanje potrebnih sustava
for dir in proc sys dev run tmp; do
    mkdir -p /mnt/$dir
done
chmod 1777 /mnt/tmp
mount --bind /dev /mnt/dev
mount --bind /dev/pts /mnt/dev/pts
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /run /mnt/run

# fstab
UUID_ROOT=$(blkid -s UUID -o value "${DISK}p2")
UUID_EFI=$(blkid -s UUID -o value "${DISK}p1")
echo "UUID=$UUID_ROOT / ext4 defaults 0 1" >> /mnt/etc/fstab
echo "UUID=$UUID_EFI /boot/efi vfat umask=0077 0 1" >> /mnt/etc/fstab
echo "/swapfile none swap sw 0 0" >> /mnt/etc/fstab

# Hostname i lokalizacija
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/default/locale
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Preuzimanje postinstall skripti
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/ubuntu-minimal/main/post-install.sh
curl -o /mnt/root/post-i3.sh https://raw.githubusercontent.com/Petar34/ubuntu-minimal/main/post-i3.sh
chmod +x /mnt/root/post-install.sh /mnt/root/post-i3.sh

# Chroot i nastavak instalacije
chroot /mnt /root/post-install.sh
chroot /mnt /root/post-i3.sh

echo -e "\n\033[1;32m[INFO] Ubuntu instalacija završena! Možeš pokrenuti reboot.\033[0m"
