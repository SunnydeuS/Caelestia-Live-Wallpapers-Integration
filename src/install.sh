#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Installing Caelestia Live Wallpapers..."

if [ "$EUID" -eq 0 ]; then
    echo "Error: Please run this script as your regular user (not root or sudo)."
    echo "Example: ./setup.sh (or ./install.sh)"
    echo "The script will request sudo privileges only when writing to system directories."
    exit 1
fi

echo "-> Checking dependencies..."
REQUIRED_PKGS=("qt6-multimedia" "qt6-multimedia-ffmpeg" "ffmpeg" "xdg-user-dirs" "python-pillow")
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
            sudo pacman -S --needed "${MISSING_PKGS[@]}" || {
                echo "Error: Failed to install dependencies. Please install manually: sudo pacman -S ${MISSING_PKGS[*]}"
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
    if ! command -v ffmpeg &>/dev/null || ! command -v xdg-user-dir &>/dev/null; then
        echo "Warning: ffmpeg or xdg-user-dirs not found in PATH."
    fi
fi

# Request sudo credentials upfront for system directory operations
sudo -v || { echo "Error: Sudo privileges required to patch system files."; exit 1; }

echo "-> Searching for Caelestia Python module path..."
PYTHON_FILE=$(find /usr/lib/python3.*/site-packages/caelestia/utils/wallpaper.py 2>/dev/null | head -n 1)

if [ -z "$PYTHON_FILE" ]; then
    echo "Error: wallpaper.py not found in /usr/lib. Ensure Caelestia is installed."
    exit 1
fi

echo "-> Detecting Caelestia Shell directories..."
USER_SHELL_DIR="$HOME/.config/quickshell/caelestia"
SYSTEM_SHELL_DIR="/etc/xdg/quickshell/caelestia"

if [ ! -d "$USER_SHELL_DIR" ] && [ ! -d "$SYSTEM_SHELL_DIR" ]; then
    echo "Error: Could not find Caelestia shell in $USER_SHELL_DIR or $SYSTEM_SHELL_DIR"
    exit 1
fi

backup_file() {
    local file="$1"
    local is_system="$2"
    if [ -f "$file" ] && [ ! -f "$file.bak" ]; then
        if [ "$is_system" = "true" ]; then
            sudo cp "$file" "$file.bak"
        else
            cp "$file" "$file.bak"
        fi
    fi
}

FILES_TO_BACKUP=(
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

echo "-> Backing up and copying modified QML files..."
if [ -d "$USER_SHELL_DIR" ]; then
    echo "   Updating user config: $USER_SHELL_DIR"
    for file in "${FILES_TO_BACKUP[@]}"; do
        backup_file "$USER_SHELL_DIR/$file" false
    done
    cp -r qml/* "$USER_SHELL_DIR/"
fi

if [ -d "$SYSTEM_SHELL_DIR" ]; then
    echo "   Updating system config: $SYSTEM_SHELL_DIR"
    for file in "${FILES_TO_BACKUP[@]}"; do
        backup_file "$SYSTEM_SHELL_DIR/$file" true
    done
    sudo cp -r qml/* "$SYSTEM_SHELL_DIR/"
fi

echo "-> Copying Python patch (Backend)..."
backup_file "$PYTHON_FILE" true
sudo cp python/wallpaper.py "$PYTHON_FILE"

echo "-> Installing thumbnail generator script..."
mkdir -p "$HOME/.local/bin"
if [ ! -w "$HOME/.local/bin" ]; then
    sudo chown -R "$USER:$USER" "$HOME/.local/bin" 2>/dev/null || true
fi
cp bin/update-caelestia-live-thumbs "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/update-caelestia-live-thumbs"

echo "-> Setting up wallpaper directories..."
PICTURES_DIR=""
if command -v xdg-user-dir &>/dev/null; then
    PICTURES_DIR=$(xdg-user-dir PICTURES 2>/dev/null)
fi

if [ -z "$PICTURES_DIR" ] || [ ! -d "$PICTURES_DIR" ]; then
    if [ -d "$HOME/Imágenes" ]; then
        PICTURES_DIR="$HOME/Imágenes"
    else
        PICTURES_DIR="$HOME/Pictures"
    fi
fi

LIVE_WALLPAPERS_DIR="$PICTURES_DIR/Live-Wallpapers"
STATIC_WALLPAPERS_DIR="$PICTURES_DIR/Wallpapers"

if [ ! -d "$LIVE_WALLPAPERS_DIR" ]; then
    mkdir -p "$LIVE_WALLPAPERS_DIR"
    echo "   Created Live-Wallpapers directory: $LIVE_WALLPAPERS_DIR"
else
    echo "   Live-Wallpapers directory already exists: $LIVE_WALLPAPERS_DIR"
fi

if [ ! -d "$STATIC_WALLPAPERS_DIR" ]; then
    mkdir -p "$STATIC_WALLPAPERS_DIR"
    echo "   Created Wallpapers directory: $STATIC_WALLPAPERS_DIR"
fi

echo "-> Generating live wallpaper thumbnails..."
"$HOME/.local/bin/update-caelestia-live-thumbs" "$LIVE_WALLPAPERS_DIR"

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
echo "Installation completed successfully!"
