#!/usr/bin/env bash

set -e -o pipefail

# Red color
red="\e[31m"
# Green color
green="\e[32m"
# Blue color
blue="\e[34m"
# Orange
orange="\e[38;5;208m"
# Reset color
reset="\e[0m"

function print() {
  echo -e "${green}================================${reset}"
  echo -e "${green}$1${reset}"
  echo -e "${green}================================${reset}"
}

function print_info() {
  echo -e "${blue}$1${reset}"
}

function print_warn() {
  echo -e "${orange}*** $1 ***${reset}"
}

function print_error() {
  echo -e "${red}!!! $1 !!!${reset}"
}

function press_to_continue() {
  print_warn "$@"
  echo "Press any key to continue..."
  read -n 1 -s
}

# Check if the user is root
if [ "$(id -u)" -eq 0 ]; then
    print_error "Script cannot run as root or with sudo since it invokes yay"
    exit 1
fi

# Set the default value of the flag
nvidia=false
first_time_setup=false

# Loop through the command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --nvidia)
            # Set the nvidia variable to true
            nvidia=true
            ;;
        --first-time-setup)
            first_time_setup=true
            ;;
        *)
            echo "Unknown argument: $key"
            ;;
    esac

    shift # Move to the next argument
done

if [[ "${first_time_setup}" = true ]]; then
  print_info "The script is running setting up EndeavourOS for the first time"
else
  print_warn "The script will be skipping first time setup for EndeavourOS"
  print_warn "This will skip installing graphics drivers and other system configurations"
  print_warn "like BTRFS snapshots"
  print_warn "if this is a mistake pass in --first-time-setup to the script"
fi

if [[ "${nvidia}" = true ]]; then
  print_info "The script will install nvidia drivers"
else
  print_warn "The script will not install nvidia drivers"
  print_warn "if this is a mistake pass in --nvidia to the script"
fi

read -p "Do you want to continue? (y/n): " response

if [[ "${response}" =~ ^[Yy]$ ]]; then
    print_info "You chose to continue."
elif [[ "${response}" =~ ^[Nn]$ ]]; then
    print_info "You chose to cancel."
    exit 0  # Exit the script with a status of 0 (success)
else
    print_error "Invalid response. Please enter 'y' for yes or 'n' for no."
    exit 1  # Exit the script with a status of 1 (error)
fi

######## Backup tools #############
print "installing backup tools"
sudo pacman -S --needed \
  syncthing \
  snapper \
  snap-pac


####### BTRFS Setup ##############

# Configuring snapper/snap-pac and DE services
if [[ "${first_time_setup}" = true ]]; then
  set +e
  set +o pipefail

  print "configuring snapper for BTRFS"

  print_info "fixing /.snapshots directory"
  sudo umount /.snapshots
  sudo rm -r /.snapshots/
  sudo snapper -c root create-config /
  sudo btrfs subvolume list /
  sudo btrfs subvolume delete /.snapshots
  sudo btrfs subvolume list /
  sudo mkdir /.snapshots
  sudo mount -a

  print_info "verify that properly mounted onto /.snapshots"
  sudo lsblk

  print_info "get subvolume default for /"
  sudo btrfs subvolume get-default /
  sudo btrfs subvolume list /

  print_info "setting default subvolume default for /"
  sudo btrfs subvolume set-default 256 /
  sudo btrfs subvolume get-default /

  sudo chown -R :wheel /.snapshots/

  print_info "turning off CoW on /var/lib/libvirt/images"
  sudo chattr -R -f +C /var/lib/libvirt/images

  print_info "checking attributes on /var/lib/libvirt/images"
  sudo lsattr -d /var/lib/libvirt/images

  print_info "enabling snapper clean up timers"
  sudo cp configs/snapper-root /etc/snapper/configs/root
  sudo systemctl enable --now snapper-timeline.timer
  sudo systemctl enable --now snapper-cleanup.timer

  set -e -o pipefail

  press_to_continue "Review all the messages above to make sure everything executed correctly"

  print_info "*** enabling bluetooth ***"
  sudo systemctl enable --now bluetooth
fi

########### nvidia drivers ###############
# nvidia drivers (if supported)
if [[ "${nvidia}" = true ]] && [[ "${first_time_setup}" = true ]]; then
  print "attempting to install nVidia drivers"
  if which nvidia-inst >/dev/null 2>&1; then
    nvidia-inst --32 --conf
  else
    print "nvidia-inst not present, make sure you're on the latest EndeavourOS"
  fi
fi

########### games ###############
print "installing gaming libraries/apps"
sudo pacman -S --needed \
  steam \
  wine \
  gamemode \
  lib32-gamemode \
  gamescope \
  jdk-openjdk \
  jdk17-openjdk \
  joyutils \
  mangohud

######### emulation ###############
# print "installing emulation libraries/apps"
# sudo pacman -S --needed \
  # dolphin-emu \
  # retroarch \
  # retroarch-assets-xmb \
  # retroarch-assets-ozone \
  # libretro-snes9x \
  # libretro-mgba \
  # libretro-mupen64plus-next \
  # libretro-shaders-slang

########### GTK2/3 and other apps/libs for DE #############
print "installing additional libraries/apps for enhanced DE experience"
sudo pacman -S --needed \
  appmenu-gtk-module \
  libappindicator-gtk3 \
  lib32-libappindicator-gtk3 \
  noto-fonts-emoji \
  tree \
  neovim \
  cracklib \
  kwalletmanager \
  gparted \
  plymouth \
  discover \
  plank \
  ksshaskpass

if [[ "${first_time_setup}" = true ]]; then
  print_warn "adding plymouth kernel parameters quiet and splash"
  sudo sed -i '1{s/$/ quiet splash/}' /etc/kernel/cmdline
  cat /etc/kernel/cmdline
  press_to_continue "verify /etc/kernel/cmdline is correct"

  sudo reinstall-kernels
else
  print_info "add \" quiet splash \" to /etc/kernel/cmdline if its not already assigned"
fi

print "adding GTK2/3 symlinks so root can have same theme as the user"

set +e
set +o pipefail
sudo ln -s $HOME/.gtkrc-2.0 /etc/gtk-2.0/gtkrc
sudo ln -s $HOME/.config/gtk-3.0/settings.ini /etc/gtk-3.0/settings.ini

press_to_continue "if setting up symlinks did not work run these commands manually at some point: 
\"sudo ln -s $HOME/.gtkrc-2.0 /etc/gtk-2.0/gtkrc\" and \"sudo ln -s $HOME/.config/gtk-3.0/settings.ini /etc/gtk-3.0/settings.ini\""

set -e -o pipefail

############ Containers #############
print "installing containerization technologies"
sudo pacman -S --needed \
  podman \
  podman-docker

# AUR package for nvidia (if supported) for GPU accelerated containers
if [[ "${nvidia}" = true  ]]; then
  yay --needed nvidia-container-toolkit
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
fi

########### X11 tools ###############
print "installing X11 addons"
sudo pacman -S --needed \
  xorg-xhost

########### VM tools ################
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

sudo cp configs/libvirtd.conf /etc/libvirt/libvirtd.conf
sudo usermod -a -G libvirt $(whoami)
sudo systemctl enable --now libvirtd.service

########## Shell ##################
print "installing ZSH"
sudo pacman -S --needed \
  zsh

print "changing default terminal to zsh"
chsh -s $(which zsh)


########## Dev Tools ###############
sudo pacman -S --needed dotnet-sdk-6.0

########## Flatpaks ###############
sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.spotify.Client
flatpak install flathub org.prismlauncher.PrismLauncher
flatpak install flathub net.davidotek.pupgui2
flatpak install flathub com.discordapp.Discord
flatpak install flathub com.github.tchx84.Flatseal
flatpak install flathub org.zdoom.GZDoom

######### AUR packages ############
print_warn "WARNING: Installing AUR packages, will require user input!"
yay --needed jetbrains-toolbox
yay --needed emulationstation-de
yay --needed visual-studio-code-bin

if [[ "${first_time_setup}" = true ]]; then
  print "Taking a snapshot of the current system configuration"
  snapper -c root create -d "*** Base System Configuration ***"
  snapper ls
fi

print "Setup complete!"
press_to_continue "Rebooting the system"
reboot
