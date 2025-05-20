#!/bin/bash

set -e  # Prekini na prvoj grešci

echo -e "\033[1;36m[INFO] Pokreće se automatska instalacija Arch Linuxa...\033[0m"

lsblk
echo ""
read -p "Upiši naziv diska (npr. /dev/sda ili /dev/nvme0n1): " DISK
read -p "[UPOZORENJE] SVI PODACI NA $DISK ĆE BITI OBRISANI. Nastavi? (da/ne): " potvrda
[[ $potvrda != "da" ]] && echo "Prekinuto." && exit 1

echo "[INFO] Isključujem swap i odmontiram sve..."
swapoff -a || true
umount -R /mnt || true

# Brisanje postojećih particija
sgdisk --zap-all "$DISK"

# Kreiranje particija
parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart ESP fat32 1MiB 513MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary ext4 513MiB 100%

# Informiraj kernel
partprobe "$DISK"
sleep 2  # pričekaj da kernel prepozna promjene

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

# Instalacija sistema
pacstrap /mnt base linux linux-firmware grub efibootmgr sudo networkmanager neovim base-devel man-db man-pages curl git

# fstab
mkdir -p /mnt/etc
genfstab -U /mnt >> /mnt/etc/fstab

# Lokalizacija i hostname
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "hr_HR.UTF-8 UTF-8" >> /mnt/etc/locale.gen

# Priprema za chroot – mount točke
mkdir -p /mnt/{proc,sys,dev,run,tmp}
chmod 1777 /mnt/tmp
mount --types proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --make-rslave /mnt/sys
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --bind /run /mnt/run

# Preuzimanje postinstall skripti
curl -o /mnt/root/post-install.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-install.sh
curl -o /mnt/root/post-i3.sh https://raw.githubusercontent.com/Petar34/arch-minimal/main/post-i3.sh

chmod +x /mnt/root/post-install.sh
chmod +x /mnt/root/post-i3.sh

# Pokretanje unutar chroota
arch-chroot /mnt /root/post-install.sh
arch-chroot /mnt /root/post-i3.sh

echo -e "\n\033[1;32m[INFO] Instalacija završena. Možeš pokrenuti reboot.\033[0m"
