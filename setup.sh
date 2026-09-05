#!/usr/bin/env bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Error: Please run setup.sh as your regular user (not root or sudo)."
    echo "The script will request sudo privileges only when writing to system files."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$SCRIPT_DIR/src"

if [ ! -d "$TOOL_DIR" ]; then
    echo "Error: Cannot find '$TOOL_DIR' directory. Please run setup.sh from the repository root."
    exit 1
fi

run_install() {
    echo ""
    echo "====================================================="
    echo "  Installing Caelestia Live Wallpapers Integration"
    echo "====================================================="
    "$TOOL_DIR/install.sh"
}

run_update() {
    echo ""
    echo "====================================================="
    echo "  Updating Caelestia Live Wallpapers Integration"
    echo "====================================================="
    if [ -d "$SCRIPT_DIR/.git" ]; then
        echo "-> Pulling latest changes from repository..."
        git -C "$SCRIPT_DIR" pull origin main
    fi
    "$TOOL_DIR/install.sh"
}

run_uninstall() {
    echo ""
    echo "====================================================="
    echo "  Uninstalling Caelestia Live Wallpapers Integration"
    echo "====================================================="
    "$TOOL_DIR/uninstall.sh"
}

# Handle command line arguments if provided
case "${1:-}" in
    -i|--install|install)
        run_install
        exit 0
        ;;
    -u|--update|update)
        run_update
        exit 0
        ;;
    -r|--uninstall|uninstall)
        run_uninstall
        exit 0
        ;;
    -h|--help|help)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  -i, --install     Install integration and restart shell"
        echo "  -u, --update      Pull latest changes and update"
        echo "  -r, --uninstall   Uninstall and restore original Caelestia files"
        echo "  -h, --help        Show this help message"
        echo ""
        echo "Run without arguments to open the interactive menu."
        exit 0
        ;;
esac

# Interactive Menu
echo ""
echo "====================================================="
echo "       Caelestia Live Wallpapers Integration"
echo "====================================================="
echo "  1) Install      Install integration & restart shell"
echo "  2) Update       Pull latest changes & re-apply"
echo "  3) Uninstall    Restore original Caelestia files"
echo "  4) Exit"
echo "====================================================="

read -rp "Please choose an option [1-4]: " choice

case "$choice" in
    1)
        run_install
        ;;
    2)
        run_update
        ;;
    3)
        run_uninstall
        ;;
    4|q|Q)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid selection: '$choice'. Exiting."
        exit 1
        ;;
esac

