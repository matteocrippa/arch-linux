#!/bin/bash

# Setup env variables

export NVME="/dev/nvme0n1"
export SSD="/dev/sda"
export PART_ID=$(blkid -o value -s UUID ${SSD}1)

export encryption_passphrase=""
export root_password=""

export encryption_passphares_home=""
export username="matteo"
export user_password=""

export hostname="earth"
export continent_city="Europe/Rome"

export swap_size="16"

export repo_url="https://raw.githubusercontent.com/matteocrippa/arch-linux/master"