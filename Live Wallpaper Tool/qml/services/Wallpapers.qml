pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils
import M3Shapes

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpaper.webp")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    readonly property var shapes: [MaterialShape.Circle, MaterialShape.Square, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Cookie6Sided]

    property var propertiesCache: ({})

    // Live Wallpaper Settings
    property bool disableAnimations: false // default: false = animations enabled
    property int animationDuration: 500 // ms, 1..2000
    readonly property bool animsEnabled: !root.disableAnimations

    property bool behaviorEnabled: true
    property bool batteryLimitEnabled: true
    property int batteryLimit: 40
    property bool pauseOnFullscreen: true
    property bool pauseOnGameMode: true
    property bool settingsLoaded: false

    FileView {
        id: liveSettingsView
        path: `${Paths.config}/Wallpaper_Settings.json`
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text().trim());
                if (data.disableAnimations !== undefined) root.disableAnimations = data.disableAnimations;
                else root.disableAnimations = false;
                if (data.animationDuration !== undefined) {
                    const v = Number(data.animationDuration);
                    root.animationDuration = Number.isFinite(v) ? Math.max(1, Math.min(2000, v)) : 500;
                } else {
                    root.animationDuration = 500;
                }
                if (data.behaviorEnabled !== undefined) root.behaviorEnabled = data.behaviorEnabled;
                if (data.batteryLimitEnabled !== undefined) root.batteryLimitEnabled = data.batteryLimitEnabled;
                if (data.batteryLimit !== undefined) root.batteryLimit = data.batteryLimit;
                if (data.pauseOnFullscreen !== undefined) root.pauseOnFullscreen = data.pauseOnFullscreen;
                if (data.pauseOnGameMode !== undefined) root.pauseOnGameMode = data.pauseOnGameMode;
            } catch(e) {
                root.disableAnimations = false;
                root.animationDuration = 500;
            }
            root.settingsLoaded = true;
        }
        onLoadFailed: err => {
            root.settingsLoaded = true;
            if (err === FileViewError.FileNotFound) {
                Qt.callLater(() => root.saveSettings());
            }
        }
    }

    function saveSettings(): void {
        let data = {
            disableAnimations: root.disableAnimations,
            animationDuration: root.animationDuration,
            behaviorEnabled: root.behaviorEnabled,
            batteryLimitEnabled: root.batteryLimitEnabled,
            batteryLimit: root.batteryLimit,
            pauseOnFullscreen: root.pauseOnFullscreen,
            pauseOnGameMode: root.pauseOnGameMode
        };
        liveSettingsView.setText(JSON.stringify(data, null, 4));
    }

    FileView {
        id: propsFileView
        path: `${Paths.home}/.cache/caelestia/wallpaper_properties.json`
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                root.propertiesCache = JSON.parse(text().trim());
            } catch(e) {}
        }
    }

    function getCategoryFor(w: FileSystemEntry): string {
        if (w.parentDir.startsWith(Paths.wallsdir)) {
            let category = w.parentDir.slice(Paths.wallsdir.length + 1);
            if (category.includes("/"))
                category = category.slice(0, category.indexOf("/"));
            return category;
        } else {
            let category = w.parentDir.split("/").pop();
            return category;
        }
    }

    function setRandom(): void {
        let arr = [];
        if (wallpapers.entries) {
            for (let i = 0; i < wallpapers.entries.length; i++) {
                arr.push(wallpapers.entries[i].path);
            }
        }
        if (liveWallpapers.entries) {
            for (let i = 0; i < liveWallpapers.entries.length; i++) {
                arr.push(liveWallpapers.entries[i].path);
            }
        }
        
        if (arr.length > 0) {
            let randomIndex = Math.floor(Math.random() * arr.length);
            setWallpaper(arr[randomIndex]);
        }
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        if (!path) {
            stopPreview();
            return;
        }
        if (showPreview && previewPath === path)
            return;

        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic") {
            if (getPreviewColoursProc.running) {
                getPreviewColoursProc.running = false;
            }
            Qt.callLater(() => {
                if (showPreview && previewPath === path && Colours.scheme === "dynamic") {
                    getPreviewColoursProc.running = true;
                }
            });
        }
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    function refreshWallpapers(): void {
        refreshProc.running = true;
    }

    Process {
        id: refreshProc
        command: ["bash", "-c", `"${Paths.home}/.local/bin/update-caelestia-live-thumbs" "${Paths.wallsdir}" "${liveWallpapers.path}"`]
        onRunningChanged: {
            if (!running) {
                let oldPath = liveWallpapers.path;
                let oldPath2 = wallpapers.path;
                let oldPropsPath = propsFileView.path;

                liveWallpapers.path = "";
                wallpapers.path = "";
                propsFileView.path = "";

                Qt.callLater(() => {
                    liveWallpapers.path = oldPath;
                    wallpapers.path = oldPath2;
                    propsFileView.path = oldPropsPath;
                });
            }
        }
    }

    property int filterMode: 0 // Default to Static
    property string colorFilter: "" // "", "red", "orange", "yellow", "green", "blue", "purple", "pink", "white", "black"

    function cycleFilterMode(reverse = false): void {
        const order = [2, 0, 1]; // 2: All, 0: Static, 1: Live
        let idx = order.indexOf(filterMode);
        if (idx === -1)
            idx = 0;
        if (reverse) {
            idx = (idx - 1 + order.length) % order.length;
        } else {
            idx = (idx + 1) % order.length;
        }
        filterMode = order[idx];
    }

    function cycleColorFilter(reverse = false): void {
        const colors = ["", "red", "orange", "yellow", "green", "blue", "purple", "pink", "white", "black"];
        let idx = colors.indexOf(colorFilter);
        if (idx === -1)
            idx = 0;
        if (reverse) {
            idx = (idx - 1 + colors.length) % colors.length;
        } else {
            idx = (idx + 1) % colors.length;
        }
        colorFilter = colors[idx];
    }

    function matchesColor(path: string, filter: string): bool {
        if (!filter || filter === "" || filter === "all")
            return true;
        let cleanPath = String(path).replace(/^file:\/\//, "");
        let entry = propertiesCache[cleanPath] || propertiesCache[path];
        if (!entry || typeof entry === "string")
            return false;
        if (entry.color === filter)
            return true;
        if (entry.colors && Array.isArray(entry.colors)) {
            if (entry.colors.includes(filter)) return true;
        }
        return false;
    }

    property var allEntries: {
        let arr = [];
        if (filterMode === 0 || filterMode === 2) {
            if (wallpapers.entries) {
                for (let i = 0; i < wallpapers.entries.length; i++) {
                    let entry = wallpapers.entries[i];
                    if (matchesColor(entry.path, colorFilter)) {
                        arr.push(entry);
                    }
                }
            }
        }
        if (filterMode === 1 || filterMode === 2) {
            if (liveWallpapers.entries) {
                for (let i = 0; i < liveWallpapers.entries.length; i++) {
                    let entry = liveWallpapers.entries[i];
                    if (matchesColor(entry.path, colorFilter)) {
                        arr.push(entry);
                    }
                }
            }
        }
        return arr;
    }

    list: allEntries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    FileSystemModel {
        id: liveWallpapers

        recursive: true
        path: Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers")
        filter: FileSystemModel.Files
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
