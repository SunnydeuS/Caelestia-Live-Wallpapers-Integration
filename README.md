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
- **Smart Pause / Game Mode**: Videos will automatically pause when a window is fullscreen (like playing a game) to save system resources. It specifically ignores browsers, so you don't lose your wallpaper while watching a YouTube video in fullscreen.
- **Auto-Thumbnail Generation**: Automatically generates `.jpg` thumbnails for your videos behind the scenes so the Caelestia menus load blazingly fast without freezing.
- **Seamless Settings Integration**: The settings menu correctly fetches and displays the live wallpaper category without bugs.

## How it works

1. It replaces the default `Image` component with a `MediaPlayer` element in Caelestia's background module.
2. It hooks into `Hypr.activeToplevel` and `GameMode.enabled` to detect fullscreen states and pause the video engine accordingly.
3. It installs a Python script (`update-caelestia-live-thumbs`) that automatically crawls your Live-Wallpapers folder and extracts a frame to serve as a thumbnail in `~/.cache/caelestia/live_thumbs/`.
4. It patches Caelestia's setting pages (`WallpaperSelect.qml`, `WallpaperCategory.qml`, and `WallpaperAndStyle.qml`) to intelligently load these thumbnails instead of crashing.

## Dependencies

Before installing, make sure you have the following packages installed on your system:
- **`ffmpeg`**: Required for extracting thumbnails behind the scenes.
- **`xdg-user-dirs`**: Used to accurately locate your Pictures directory.
- **`qt6-multimedia`** and **`qt6-multimedia-ffmpeg`** (or your distro's equivalent backend): Required by the QML `MediaPlayer` to actually play the video files in the UI.

## Where do I put my Live Wallpapers?
Simply place your `.mp4`, `.mkv`, or `.webm` files inside `~/Pictures/Live-Wallpapers` (or whatever your equivalent localized folder is, as long as it's next to your normal `Wallpapers` folder). The script will detect them automatically.

## Installation

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/SunnydeuS/Caelestia-Live-Wallpapers-Integration.git
   cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
   ```

2. Run the installation script with sudo privileges:
   ```bash
   sudo ./install.sh
   ```

3. Restart your system to apply the changes and properly load image/video resolutions:
   ```bash
   systemctl reboot
   ```

## Updating

To get the latest changes from this repository, run the updater script:
```bash
cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
sudo ./update.sh
```

## Uninstallation

If you wish to remove this modification and revert to the stock Caelestia behavior, run the uninstallation script:
```bash
cd "Caelestia-Live-Wallpapers-Integration/Live Wallpaper Tool"
sudo ./uninstall.sh
```

## Acknowledgements

Special thanks to [**AdiAmbassador**](https://github.com/adiambassador) for the inspiration behind this project. And of course, massive thanks to the **Caelestia** team for their incredible shell.
