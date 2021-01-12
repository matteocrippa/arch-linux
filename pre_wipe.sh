#!/bin/bash

# Env variables
. vars.sh

# Install gdisk
pacman -Sy gdisk

# Wipe NVME
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $NVME
  x # expert mode
  z # wipe disk
  y # confirm
  y # confirm
EOF

# Wipe SSD
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk $SSD
  x # expert mode
  z # wipe disk
  y # confirm
  y # confirm
EOF