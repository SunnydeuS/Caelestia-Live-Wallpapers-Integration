#!/bin/bash

echo "Updating Caelestia Live Wallpapers Integration..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo in order to update the installation."
  exit 1
fi

# Change to the script's directory
cd "$(dirname "$0")" || exit 1

# Go up one level to the git root to perform git pull
cd ..

echo "-> Pulling latest changes from Git..."
sudo -u ${SUDO_USER:-$USER} git pull

# Go back to the tool directory to run the installer
cd "Live Wallpaper Tool" || exit 1

echo "-> Running installation script..."
./install.sh
