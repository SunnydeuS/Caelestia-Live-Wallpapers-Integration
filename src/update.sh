#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Updating Caelestia Live Wallpapers Integration..."

if [ "$EUID" -eq 0 ]; then
    echo "Error: Please run this script as your regular user (not root or sudo)."
    echo "Example: ./setup.sh --update (or ./update.sh)"
    exit 1
fi

if [ -d "$REPO_DIR/.git" ]; then
    echo "-> Pulling latest changes from Git..."
    git -C "$REPO_DIR" pull origin main
fi

echo "-> Running installation script..."
"$SCRIPT_DIR/install.sh"

