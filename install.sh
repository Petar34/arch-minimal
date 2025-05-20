#!/bin/bash

set -e  # Prekini na prvoj grešci

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
genfstab -U /mnt >> /mnt/etc/fstab

# Lokalizacija i hostname
echo "admin" > /mnt/etc/hostname
echo "LANG=hr_HR.UTF-8" > /mnt/etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Zagreb /mnt/etc/localtime

# Lokalizacija (priprema za post-install)
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "hr_HR.UTF-8 UTF-8" >> /mnt/etc/locale.gen

# Unutar chroota: dodaj post-install skriptu
cat << 'EOF' > /mnt/root/post-install.sh
#!/bin/bash
set -e

USERNAME=admin
PASSWORD=admin

# Generiraj locale
locale-gen

# Dodaj korisnika
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Omogući mrežu
systemctl enable NetworkManager

# Instalacija GRUB bootloadera
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Postavi root lozinku
echo "root:$PASSWORD" | chpasswd

echo "[+] Post-install završio. Spreman za reboot."
EOF

chmod +x /mnt/root/post-install.sh

# Pokreni unutar chroota
arch-chroot /mnt /root/post-install.sh

echo -e "\n[*] Instalacija završena. Reboot za pokretanje Arch Linuxa..."
sleep 5
reboot
