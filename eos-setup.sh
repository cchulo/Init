#!/usr/bin/env bash

function print() {
    echo "================================"
    echo "$1"
    echo "================================"
}

#!/bin/bash

# Set the default value of the flag
nvidia=false

# Loop through the command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --nvidia)
            # Set the nvidia variable to true
            nvidia=true
            shift # past argument
            ;;
        *)
            # Ignore other arguments
            shift # past argument
            ;;
    esac
done

# nvidia drivers (if supported)
if [[ "${nvidia}" = true ]]; then
  print "attempting to install nVidia drivers"
  if which nvidia-inst >/dev/null 2>&1; then
    nvidia-inst --32 --conf
  else
    print "nvidia-inst not present, make sure you're on the latest EndeavourOS"
  fi
fi

# games
print "installing gaming libraries/apps"
sudo pacman -S --needed \
  discord \
  steam \
  spotify-launcher \
  wine \
  gamemode \
  lib32-gamemode \
  gamescope \
  jdk-openjdk \
  jdk17-openjdk

# emulation
print "installing emulation libraries/apps"
sudo pacman -S --needed \
  dolphin-emu \
  retroarch \
  retroarch-assets-xmb \
  retroarch-assets-ozone \
  libretro-snes9x \
  libretro-mgba \
  libretro-mupen64plus-next \
  libretro-shaders-slang

# GTK2/3 and other apps for DE
print "installing additional libraries/apps for enhanced DE experience"
sudo pacman -S --needed \
  appmenu-gtk-module \
  libappindicator-gtk3 \
  lib32-libappindicator-gtk3 \
  noto-fonts-emoji \
  tree \
  neovim \
  plymouth

# Backup tools
print "installing backup tools"
sudo pacman -S --needed \
  syncthing

# Containers
print "installing containerization technologies"
sudo pacman -S --needed \
  podman \
  podman-docker

# AUR package for nvidia (if supported) for GPU accelerated containers
if [[ "${nvidia}" = true  ]]; then
  yay nvidia-container-toolkit
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
fi

# X11 tools
print "installing X11 addons"
sudo pacman -S --needed \
  xorg-xhost

# VM tools
print "installing QEMU/KVM/VMM"
sudo pacman -S --needed \
  qemu-desktop \
  virt-manager \
  virt-viewer \
  dnsmasq \
  vde2 \
  bridge-utils \
  openbsd-netcat \
  dmidecode

# Shell
print "installing ZSH"
sudo pacman -S --needed \
  zsh

print "changing default terminal to zsh"
chsh -s $(which zsh)

# AUR packages
print "WARNING: Installing AUR packages, will require user input!"
yay \
  visual-studio-code-bin \
  jetbrains-toolbox \
  prismlauncher-qt5-bin \
  emulationstation-de \
  protonup-qt-bin
