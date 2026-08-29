#!/bin/bash

echo "Installing Caelestia Live Wallpapers..."

# Check for sudo permissions to copy system files
if [ "$EUID" -ne 0 ]; then
  echo "Please run the script with sudo in order to modify QML and Python files."
  exit 1
fi

echo "-> Checking dependencies..."
REQUIRED_PKGS=("qt6-multimedia" "qt6-multimedia-ffmpeg" "ffmpeg" "xdg-user-dirs")
MISSING_PKGS=()

if command -v pacman &>/dev/null; then
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        echo "Missing required packages: ${MISSING_PKGS[*]}"
        read -rp "Would you like to install missing dependencies now with pacman? [Y/n] " answer
        answer=${answer:-Y}
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            pacman -S --needed "${MISSING_PKGS[@]}" || {
                echo "Error: Failed to install dependencies. Please install them manually: sudo pacman -S ${MISSING_PKGS[*]}"
                exit 1
            }
        else
            echo "Error: Required dependencies are not installed. Aborting installation."
            exit 1
        fi
    else
        echo "All dependencies satisfied."
    fi
else
    # Fallback check for non-pacman distros
    if ! command -v ffmpeg &>/dev/null || ! command -v xdg-user-dir &>/dev/null; then
        echo "Warning: ffmpeg or xdg-user-dirs not found in PATH."
    fi
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
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/PageCompRegistry.qml
backup_if_exists /etc/xdg/quickshell/caelestia/modules/nexus/WindowFactory.qml
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

echo "-> Setting up wallpaper directories..."
PICTURES_DIR=""
if command -v xdg-user-dir &>/dev/null; then
    PICTURES_DIR=$(sudo -u "$REAL_USER" xdg-user-dir PICTURES 2>/dev/null)
fi

if [ -z "$PICTURES_DIR" ] || [ ! -d "$PICTURES_DIR" ]; then
    if [ -d "$USER_HOME/Imágenes" ]; then
        PICTURES_DIR="$USER_HOME/Imágenes"
    else
        PICTURES_DIR="$USER_HOME/Pictures"
    fi
fi

LIVE_WALLPAPERS_DIR="$PICTURES_DIR/Live-Wallpapers"
STATIC_WALLPAPERS_DIR="$PICTURES_DIR/Wallpapers"

if [ ! -d "$LIVE_WALLPAPERS_DIR" ]; then
    mkdir -p "$LIVE_WALLPAPERS_DIR"
    chown "$REAL_USER:$REAL_USER" "$LIVE_WALLPAPERS_DIR"
    echo "   Created Live-Wallpapers directory: $LIVE_WALLPAPERS_DIR"
else
    echo "   Live-Wallpapers directory already exists: $LIVE_WALLPAPERS_DIR"
fi

if [ ! -d "$STATIC_WALLPAPERS_DIR" ]; then
    mkdir -p "$STATIC_WALLPAPERS_DIR"
    chown "$REAL_USER:$REAL_USER" "$STATIC_WALLPAPERS_DIR"
    echo "   Created Wallpapers directory: $STATIC_WALLPAPERS_DIR"
fi

echo "Installation completed! Please restart your system (systemctl reboot) to apply changes."
