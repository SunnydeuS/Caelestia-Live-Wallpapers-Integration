pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

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

    property var propertiesCache: ({})

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
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
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

    property var allEntries: {
        let arr = [];
        if (filterMode === 0 || filterMode === 2) {
            if (wallpapers.entries) {
                for (let i = 0; i < wallpapers.entries.length; i++) {
                    arr.push(wallpapers.entries[i]);
                }
            }
        }
        if (filterMode === 1 || filterMode === 2) {
            if (liveWallpapers.entries) {
                for (let i = 0; i < liveWallpapers.entries.length; i++) {
                    arr.push(liveWallpapers.entries[i]);
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
