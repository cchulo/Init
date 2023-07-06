#!/usr/bin/env bash

function print() {
    echo "================================"
    echo "$1"
    echo "================================"
}

# games
print "installing game tools"
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
  tree

# Backup tools
print "installing backup tools"
sudo pacman -S --needed \
  syncthing

# Containers
print "installing containerization technologies"
sudo pacman -S --needed \
  podman \
  podman-docker

# X11 tools
print "installing X11 addons"
sudo pacman -S --needed \
  xorg-xhost

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

print "WARNING: Installing AUR packages, will require user input!"
yay \
  visual-studio-code-bin \
  jetbrains-toolbox \
  prismlauncher-qt5-bin \
  emulationstation-de \
  protonup-qt-bin \
  nvidia-container-toolkit
