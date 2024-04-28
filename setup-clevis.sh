#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Check if there's a partition parameter
if [ -z "$1" ]; then
    echo "Error: No partition specified."
    exit 1
fi

# Check if the partition exists
if [ ! -b "$1" ]; then
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
if ! blkid "$1" | grep -q "TYPE=\"crypto_LUKS\""; then
    echo "Error: The specified partition is not a LUKS partition."
    exit 1
fi

# Check if the LUKS partition is already bound to a Tang server
if clevis luks list -d "$1" | grep -q "tang"; then
    echo "The LUKS partition is already bound to a Tang server."
else
    # Bind the LUKS partition to the Tang server
    if clevis luks bind -d "$1" tang '{"url":"http://10.0.0.1:7500"}'; then
        echo "Successfully bound the LUKS partition to the Tang server."
    else
        echo "Failed to bind the LUKS partition to the Tang server."
        exit 1
    fi
fi
