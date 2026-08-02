#!/bin/bash

echo "Installing Caelestia Live Wallpapers..."

# Check for sudo permissions to copy system files
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo in order to modify QML and Python files."
  exit
fi

# The real user running sudo (to copy scripts to ~/.local/bin)
REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "-> Searching for Caelestia Python module path..."
PYTHON_FILE=$(find /usr/lib/python3.*/site-packages/caelestia/utils/wallpaper.py 2>/dev/null | head -n 1)

if [ -z "$PYTHON_FILE" ]; then
    echo "wallpaper.py not found in /usr/lib. Ensure Caelestia is installed."
    exit 1
fi

echo "-> Backing up original files..."
backup_if_exists() {
    if [ -f "$1" ] && [ ! -f "$1.bak" ]; then
        cp "$1" "$1.bak"
    fi
}

backup_if_exists /etc/xdg/quickshell/caelestia/modules/background/Wallpaper.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/launcher/items/WallpaperItem.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/launcher/Content.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/launcher/WallpaperList.qml
backup_if_exists /etc/xdg/quickshell/caelestia/services/Wallpapers.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/pages/wallandstyle/WallpaperSelect.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/pages/wallandstyle/WallpaperCategory.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/pages/WallpaperAndStyle.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/common/WallItem.qml
backup_if_exists "$PYTHON_FILE"

echo "-> Copying modified QML files..."
cp -r qml/* /etc/xdg/quickshell/caelestia/

echo "-> Copying Python patch (Backend)..."
cp python/wallpaper.py "$PYTHON_FILE"

echo "-> Installing thumbnail generator script..."
mkdir -p "$USER_HOME/.local/bin"
cp bin/update-caelestia-live-thumbs "$USER_HOME/.local/bin/"
chmod +x "$USER_HOME/.local/bin/update-caelestia-live-thumbs"
chown "$REAL_USER:$REAL_USER" "$USER_HOME/.local/bin/update-caelestia-live-thumbs"

echo "Installation completed! Please restart your system (systemctl reboot) to apply changes."
