#!/bin/bash

format() {
  echo "Formating disk"

  swapoff /dev/sb2
  umount -R /mnt

  mkswap /dev/sdb2
  mkfs.ext4 -L root /dev/sdb3
  mkfs.ext4 -L home /dev/sdb4
  mkfs.fat -F32 -n boot /dev/sdb1


  echo "Mouting files"

  mount /dev/sdb3 /mnt
  mount --mkdir /dev/sdb4 /mnt/home
  mount --mkdir /dev/sdb1 /mnt/boot
  swapon /dev/sdb2
}

base_install() {
  echo "Installing Arch"
  pacstrap -K /mnt base linux linux-firmware
  genfstab -U /mnt >> /mnt/etc/fstab
}


install_x() {
  echo "Installing X"
  pacman -S --noconfirm nvidia nvidia-settings nvidia-utils
  pacman -S --noconfirm xorg xorg-xinit xorg-xev arandr
  pacman -S --noconfirm awesomewm
  cat <<EOF> /home/rmarra/.xinitrc
xrandr --output DP-0 --off --output DP-1 --off --output HDMI-0 --mode 1920x1080 --pos 1080x298 --rotate normal --output HDMI-1 --mode 1920x1080 --pos 0x0 --rotate right
setxkbmap -layout us -variant intl
exec /usr/bin/awesome >> ~/.cache/awesome/stdout 2>> ~/.cache/awesome/stderr
EOF
}

install_audio() {
  echo "Installing Audio"
  pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol-qt alsa-utils
}

set_timezone() {
  echo "Setting TZ"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  hwclock --systohc
}

set_locale() {
  echo "Setting locale"
  cat <<EOF> /etc/locale.gen
en_US.UTF-8 UTF-8
pt-BR.UTF-8 UTF-8
EOF
  locale-gen
  echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
}

create_user() {
  echo "Create user"
  useradd -m -s /bin/zsh -G wheel "rmarra"
  echo -en "123456\n123456" | passwd "rmarra"
}

setup_sudo() {
  echo "Setup SUDO"
  pacman -S --noconfirm sudo
  echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
}

config_misc() {
  echo "Config MISC"
  echo "KEYMAP=us-acentos" >> /etc/vconsole.conf
  echo "paddle" > /etc/hostname
}

config_bootctl() {
  echo "bootinstall"
  bootctl install
  cat <<EOF >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=LABEL=root rw
EOF
}

initial_install() {
  format
  base_install
}

chroot_setup() {
  set_timezone
  set_locale
  config_misc
  config_bootctl
  create_user
  setup_sudo
  install_x
  install_audio
}

[[ $1 == "chroot" ]] && chroot_setup || initial_install
