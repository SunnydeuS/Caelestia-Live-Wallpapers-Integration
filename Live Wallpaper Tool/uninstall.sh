#!/bin/bash

echo "Uninstalling Caelestia Live Wallpapers Integration..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo in order to restore QML and Python files."
  exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "-> Restoring original QML files..."
FILES=(
    "modules/background/Wallpaper.qml"
    "modules/launcher/items/WallpaperItem.qml"
    "modules/launcher/Content.qml"
    "modules/launcher/WallpaperList.qml"
    "services/Wallpapers.qml"
    "modules/nexus/pages/wallandstyle/WallpaperSelect.qml"
    "modules/nexus/pages/wallandstyle/WallpaperCategory.qml"
    "modules/nexus/pages/WallpaperAndStyle.qml"
    "modules/nexus/common/WallItem.qml"
    "modules/nexus/PageCompRegistry.qml"
    "modules/nexus/WindowFactory.qml"
)

for file in "${FILES[@]}"; do
    if [ -f "/etc/xdg/quickshell/caelestia/$file.bak" ]; then
        mv "/etc/xdg/quickshell/caelestia/$file.bak" "/etc/xdg/quickshell/caelestia/$file"
        echo "Restored $file"
    fi
done

if [ -f "/etc/xdg/quickshell/caelestia/modules/launcher/ColorFilterBar.qml" ]; then
    rm -f "/etc/xdg/quickshell/caelestia/modules/launcher/ColorFilterBar.qml"
    echo "Removed ColorFilterBar.qml"
fi

if [ -f "/etc/xdg/quickshell/caelestia/modules/nexus/pages/wallandstyle/WallpaperSettings.qml" ]; then
    rm -f "/etc/xdg/quickshell/caelestia/modules/nexus/pages/wallandstyle/WallpaperSettings.qml"
    echo "Removed WallpaperSettings.qml"
fi

echo "-> Searching for Caelestia Python module path..."
PYTHON_FILE=$(find /usr/lib/python3.*/site-packages/caelestia/utils/wallpaper.py 2>/dev/null | head -n 1)

if [ -n "$PYTHON_FILE" ] && [ -f "$PYTHON_FILE.bak" ]; then
    mv "$PYTHON_FILE.bak" "$PYTHON_FILE"
    echo "Restored wallpaper.py"
fi

echo "-> Removing thumbnail generator script..."
if [ -f "$USER_HOME/.local/bin/update-caelestia-live-thumbs" ]; then
    rm "$USER_HOME/.local/bin/update-caelestia-live-thumbs"
    echo "Removed update-caelestia-live-thumbs"
fi

echo "Uninstallation completed! Please restart your system (systemctl reboot) to apply changes."
