#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Uninstalling Caelestia Live Wallpapers Integration..."

if [ "$EUID" -eq 0 ]; then
    echo "Error: Please run this script as your regular user (not root or sudo)."
    echo "Example: ./setup.sh --uninstall (or ./uninstall.sh)"
    echo "The script will request sudo privileges only when modifying system directories."
    exit 1
fi

sudo -v || { echo "Error: Sudo privileges required to restore system files."; exit 1; }

USER_SHELL_DIR="$HOME/.config/quickshell/caelestia"
SYSTEM_SHELL_DIR="/etc/xdg/quickshell/caelestia"

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

echo "-> Restoring original QML files..."
if [ -d "$USER_SHELL_DIR" ]; then
    echo "   Restoring user config: $USER_SHELL_DIR"
    for file in "${FILES[@]}"; do
        if [ -f "$USER_SHELL_DIR/$file.bak" ]; then
            mv "$USER_SHELL_DIR/$file.bak" "$USER_SHELL_DIR/$file"
            echo "   Restored $file"
        fi
    done
    rm -f "$USER_SHELL_DIR/modules/launcher/ColorFilterBar.qml"
    rm -f "$USER_SHELL_DIR/modules/nexus/pages/wallandstyle/WallpaperSettings.qml"
fi

if [ -d "$SYSTEM_SHELL_DIR" ]; then
    echo "   Restoring system config: $SYSTEM_SHELL_DIR"
    for file in "${FILES[@]}"; do
        if [ -f "$SYSTEM_SHELL_DIR/$file.bak" ]; then
            sudo mv "$SYSTEM_SHELL_DIR/$file.bak" "$SYSTEM_SHELL_DIR/$file"
            echo "   Restored $file"
        fi
    done
    sudo rm -f "$SYSTEM_SHELL_DIR/modules/launcher/ColorFilterBar.qml"
    sudo rm -f "$SYSTEM_SHELL_DIR/modules/nexus/pages/wallandstyle/WallpaperSettings.qml"
fi

echo "-> Searching for Caelestia Python module path..."
PYTHON_FILE=$(find /usr/lib/python3.*/site-packages/caelestia/utils/wallpaper.py 2>/dev/null | head -n 1)

if [ -n "$PYTHON_FILE" ] && [ -f "$PYTHON_FILE.bak" ]; then
    sudo mv "$PYTHON_FILE.bak" "$PYTHON_FILE"
    echo "   Restored wallpaper.py"
fi

echo "-> Removing thumbnail generator script..."
if [ -f "$HOME/.local/bin/update-caelestia-live-thumbs" ]; then
    if [ ! -w "$HOME/.local/bin" ]; then
        sudo chown -R "$USER:$USER" "$HOME/.local/bin" 2>/dev/null || true
    fi
    rm -f "$HOME/.local/bin/update-caelestia-live-thumbs" 2>/dev/null || sudo rm -f "$HOME/.local/bin/update-caelestia-live-thumbs"
    echo "   Removed update-caelestia-live-thumbs"
fi

echo "-> Restarting Caelestia shell..."
if command -v caelestia &>/dev/null; then
    caelestia shell -k 2>/dev/null || true
    sleep 1
    caelestia shell -d 2>/dev/null || true
    echo "   Caelestia shell restarted successfully."
else
    echo "   Note: 'caelestia' command not found. Reload your shell manually (e.g. Ctrl+Super+Alt+R)."
fi

echo ""
echo "Uninstallation completed successfully!"
