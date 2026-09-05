https://github.com/user-attachments/assets/283815df-d370-4001-bbd2-b3b4dd41bd2c

https://github.com/user-attachments/assets/503f5210-0bdb-415a-88fd-2f328af92baf

# Caelestia Live Wallpapers Integration

An unofficial integration made by me for the [Caelestia](https://github.com/caelestia-dots/caelestia) ecosystem that seamlessly adds native support for Video Live Wallpapers (.mp4, .mkv, .webm) directly into the UI.

> **Note**: Full credit for the shell goes to the Caelestia team. This project is simply my custom integration to add live wallpaper capabilities and small additional features.

*Also available in [Spanish (Español)](README_es.md).*

## Compatibility Note
This installation script relies on standard Linux filesystem paths and write-access to `/usr/lib` and `/etc`. It is primarily designed and tested for **Arch Linux** and its derivatives (CachyOS, EndeavourOS, etc.).
- Make sure you have Caelestia installed before running this script. This modification patches system files in `/etc/xdg/quickshell/caelestia/` and creates backups of the original files (`.bak`).

## Features

- **Native UI Integration**: Live wallpapers appear beautifully in the Caelestia Quick Launcher (>Wallpaper) and in the Settings menus (Nexus), side-by-side with your static wallpapers.
- **Smart Pause / Game Mode**: Videos will automatically pause when a window is fullscreen (like playing a game) to save system resources.
- **Auto-Thumbnail Generation**: Automatically generates `.jpg` thumbnails for the videos.
- **Settings Integration (Nexus)**: The settings menu correctly fetches and displays the live wallpaper category.

## Shortcuts

When using the carousel (`>wallpaper`):

- **`Tab`**: Selects a random wallpaper.
- **`Shift + Tab`** / **`Backtab`**: Cycles through color filters.
- **`Left` / `Right` Arrow**: Switches view between *Static*, *Live*, and *All* wallpapers.
- **`Ctrl + R`**: Refreshes the wallpaper list and regenerates thumbnails.

## How it works

1. It replaces the default `Image` component with a `MediaPlayer` element in Caelestia's background module.
2. It uses `Hypr.activeToplevel` and `GameMode.enabled` to detect fullscreen states and pause the video engine.
3. It installs a Python script (`update-caelestia-live-thumbs`) that automatically crawls your Live-Wallpapers folder and extracts a frame to serve as a thumbnail in `~/.cache/caelestia/live_thumbs/`.
4. It patches Caelestia's setting pages (`WallpaperSelect.qml`, `WallpaperCategory.qml`, and `WallpaperAndStyle.qml`) to load the thumbnails instead of crashing.

## Dependencies

Install the required packages with pacman (Arch Linux):

```bash
sudo pacman -S --needed ffmpeg xdg-user-dirs qt6-multimedia qt6-multimedia-ffmpeg python-pillow
```

*(Note: `install.sh` will also check for these packages and prompt to install them automatically).*

- **`ffmpeg`**: Required for extracting video frames for thumbnails.
- **`xdg-user-dirs`**: Used to locate your Pictures directory.
- **`qt6-multimedia`** & **`qt6-multimedia-ffmpeg`**: Required by QML `MediaPlayer` to render and play video wallpapers natively.
- **`python-pillow`**: Required for thumbnail creation, color quantization, and palette classification.

## Where do I put my Live Wallpapers?
Simply place your `.mp4`, `.mkv`, or `.webm` files inside `~/Pictures/Live-Wallpapers` (or your localized Pictures folder). The integration will detect them automatically.

## Updating the Wallpaper Database & Thumbnails

Whenever you add, remove, or modify live wallpapers, you can update the database and regenerate thumbnails using either method:

### 1. From the UI (GUI)
- Open the wallpaper launcher (`>wallpaper`) and press **`Ctrl + R`**, or click the **Refresh** button in the launcher or Nexus wallpaper settings.

### 2. From the Terminal (CLI)
- Run the thumbnail updater command directly in your terminal:
  ```bash
  update-caelestia-live-thumbs
  ```
- To also index all your static wallpapers into the database (for color palette extraction and resolution tags):
  ```bash
  update-caelestia-live-thumbs --include-static
  ```

> **Where data is stored:**
> - Thumbnails: `~/.cache/caelestia/live_thumbs/`
> - Wallpaper metadata & color database: `~/.cache/caelestia/wallpaper_properties.json`

## Installation & Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/amitxd75/Caelestia-Live-Wallpapers-Integration.git
   cd Caelestia-Live-Wallpapers-Integration
   ```

2. Run the interactive setup tool:
   ```bash
   ./setup.sh
   ```

This launches an interactive menu to easily install, update, or uninstall the integration:
```text
=====================================================
       Caelestia Live Wallpapers Integration
=====================================================
  1) Install      Install integration & restart shell
  2) Update       Pull latest changes & re-apply
  3) Uninstall    Restore original Caelestia files
  4) Exit
=====================================================
Please choose an option [1-4]: 
```

You can also pass CLI flags directly for non-interactive execution:
```bash
# Direct install
./setup.sh --install

# Direct update (pulls git changes and re-applies)
./setup.sh --update

# Direct uninstall (restores original files)
./setup.sh --uninstall
```

The script automatically detects your Caelestia user and system directories, backs up original files, generates initial thumbnails, and **automatically restarts the Caelestia shell** for your active session.

If you ever need to manually restart the shell, run:
```bash
caelestia shell
```
(or press `Ctrl+Super+Alt+R`).

## Acknowledgements

Special thanks to [**AdiAmbassador**](https://github.com/adiambassador) for the inspiration behind this project. And of course, massive thanks to the **Caelestia** team.
