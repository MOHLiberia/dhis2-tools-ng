#!/usr/bin/env bash

set -e

echo ">>> Updating system packages..."
apt-get -y update
apt-get -y upgrade

# -------------------------------------------------------------------
# Ensure snapd is installed
# -------------------------------------------------------------------
echo ">>> Checking for Snap installation..."
if ! command -v snap >/dev/null 2>&1; then
    echo ">>> Installing snapd..."
    apt-get install -y snapd
    systemctl enable --now snapd
    systemctl enable --now apparmor || true
    ln -s /var/lib/snapd/snap /snap || true
    echo ">>> Snap installed successfully."
else
    echo ">>> Snap is already installed."
fi

# -------------------------------------------------------------------
# Remove old LXD installed via apt (usually 3.0.3)
# -------------------------------------------------------------------
echo ">>> Removing old apt LXD if present..."
sudo apt -y remove --purge lxd || true
sudo apt -y autoremove -y || true

# -------------------------------------------------------------------
# Install LXD from snap
# -------------------------------------------------------------------
echo ">>> Installing LXD (snap)..."
snap install lxd --channel=4.0/stable

# -------------------------------------------------------------------
# Initialize LXD system with preseed
# -------------------------------------------------------------------
echo ">>> Initializing LXD..."
cat configs/lxd_preseed | sudo lxd init --preseed

# -------------------------------------------------------------------
# Apply kernel tweaks
# -------------------------------------------------------------------
echo ">>> Applying kernel tweaks..."
cat configs/sysctl >> /etc/sysctl.conf

sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0

# -------------------------------------------------------------------
# Run additional install scripts
# -------------------------------------------------------------------
echo ">>> Running install scripts..."
source install_scripts.sh

# -------------------------------------------------------------------
# Create the containers
# -------------------------------------------------------------------
echo ">>> Creating containers..."
source create_containers.sh

echo ">>> LXD setup complete."
