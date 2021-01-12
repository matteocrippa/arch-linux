#!/bin/bash

# Setup env variables

export NVME="/dev/nvme0n1"
export SSD="/dev/sda"

export encryption_passphrase=""
export root_password=""

export encryption_passphares_home=""
export username="matteo"
export user_password=""
export encrypt_key_file=$(cat .ssd_key)

export hostname="earth"
export continent_city="Europe/Rome"

export swap_size="16"

export repo_url="https://raw.githubusercontent.com/matteocrippa/arch-linux/master"