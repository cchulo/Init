#!/usr/bin/env bash

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

partition="$1"

# Check if the partition exists
if [ ! -b "${partition}" ]; then
    echo "Error: The specified partition does not exist."
    exit 1
fi

# Ensure the partition is a LUKS partition
if ! blkid "${partition}" | grep -q "TYPE=\"crypto_LUKS\""; then
    echo "Error: The specified partition: ${partition} is not a LUKS partition."
    exit 1
fi

systemd-cryptenroll --fido2-device=auto "${partition}
