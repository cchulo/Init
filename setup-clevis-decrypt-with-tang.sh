#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

partition="$1"
tang_server="$2"
port="${3:-7500}"

# Check if there's a partition parameter
if [ -z "${partition}" ]; then
    echo "Error: No partition specified."
    exit 1
fi

if [ -z "${tang_server}" ]; then
    echo "Error: No tang server specified."
    exit 1
fi

# Ping the IP address
if ping -c 1 -W 3 "${tang_server}" &> /dev/null; then
    echo "${tang_server} is reachable."
else
    echo "${tang_server} is not reachable."
    exit 1
fi

# Check if the partition exists
if [ ! -b "${partition}" ]; then
    echo "Error: The specified partition does not exist."
    exit 1
fi

# Check if clevis-dracut is installed
if ! rpm -q clevis-dracut &>/dev/null; then
    echo "clevis-dracut is not installed. Installing..."
    if ! rpm-ostree install clevis-dracut; then
        echo "Failed to install clevis-dracut."
        exit 1
    fi
fi

# Ensure the partition is a LUKS partition
if ! blkid "${partition}" | grep -q "TYPE=\"crypto_LUKS\""; then
    echo "Error: The specified partition is not a LUKS partition."
    exit 1
fi

# Check if the LUKS partition is already bound to a Tang server
if clevis luks list -d "${partition}" | grep -q "tang"; then
    echo "The LUKS partition is already bound to a Tang server."
else
    # Bind the LUKS partition to the Tang server
    echo "attempting to bind ${partition} to the tang server ${tang_server}:${port}"
    if clevis luks bind -d "${partition}" tang "{\"url\":\"http://${tang_server}:${port}\"}"; then
        echo "Successfully bound the LUKS partition to the Tang server."
    else
        echo "Failed to bind the LUKS partition to the Tang server."
        exit 1
    fi
fi
