#!/bin/bash

confirm() {
  read -p "Press any key to continue!!"
}

format() {
  echo "Formating disk"
  confirm

  mkswap /dev/sdb2
  mkfs.ext4 -l root /dev/sdb3
  mkfs.ext4 -l home /dev/sdb4
  mkfs.fat -F32 -l boot /dev/sdb1


  echo "Mouting files"

  mount /dev/sdb3 /mnt
  mount --mkdir /dev/sdb4 /mnt/home
  mount --mkdir /dev/sdb1 /mnt/boot
  swapon /dev/sdb2
}

base_install() {
  echo "Installing Arch"
  confirm
  pacstrap -K /mnt base linux linux-firmware
  genfstab -U /mnt >> /mnt/etc/fstab
}


install_x() {
  echo "Installing X"
  confirm
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
  confirm
  pacman -S --noconfirm pulseaudio pulseaudio-alsa pavucontrol-qt alsa-utils
}

set_timezone() {
  echo "Setting TZ"
  confirm
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  hwclock --systohc
}

set_locale() {
  echo "Setting locale"
  confirm
  cat <<EOF> /tmp/teste
en_US.UTF-8 UTF-8
pt-BR.UTF-8 UTF-8
EOF
  locale-gen
  echo "LANG=pt_BR.UTF-8" >> /etc/locale.conf
}

create_user() {
  echo "Create user"
  confirm
  useradd -m -s /bin/zsh -G wheel "rmarra"
  echo -en "123456\n123456" | passwd "rmarra"
}

setup_sudo() {
  echo "Setup SUDO"
  confirm
  pacman -S --noconfirm sudo
  echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
}

config_misc() {
  echo "Config MISC"
  confirm
  echo "KEYMAP=us-acentos" >> /etc/vconsole.conf
  echo "paddle" > /etc/hostname
}

config_bootctl() {
  echo "bootinstall"
  confirm
  bootctl install
  cat <<EOF >> /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=LABEL=root ibt=off nvidia_drm.modeset=1 rw
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
