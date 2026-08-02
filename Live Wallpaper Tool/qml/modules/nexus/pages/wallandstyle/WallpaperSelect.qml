pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Components
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpapers")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: qsTr("Browse")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: qsTr("Select an image")
                    filterLabel: qsTr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: qsTr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Quickshell.shellPath("assets/wallpaper.webp")
            text: qsTr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(Quickshell.shellPath("assets/wallpaper.webp"));
                root.nState.closeSubPage();
            }
        }

        Item {
            Layout.topMargin: Tokens.spacing.large
            Layout.fillWidth: true
            implicitHeight: Math.max(titleText.implicitHeight, filterButtons.implicitHeight)

            StyledText {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Local wallpapers")
                font: Tokens.font.title.small
            }

            Row {
                id: filterButtons
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                IconTextButton {
                    icon: "image"
                    text: qsTr("Static")
                    isToggle: true
                    checked: Wallpapers.filterMode === 0
                    onClicked: Wallpapers.filterMode = 0
                }
                IconTextButton {
                    icon: "smart_display"
                    text: qsTr("Live")
                    isToggle: true
                    checked: Wallpapers.filterMode === 1
                    onClicked: Wallpapers.filterMode = 1
                }
                IconTextButton {
                    id: refreshBtn
                    
                    icon: isLoading ? hourglassFrames[dotPhase] : "refresh"
                    text: isLoading ? qsTr("Refreshing") : qsTr("Refresh")
                    
                    property bool isLoading: false
                    property int dotPhase: 0
                    property var hourglassFrames: [
                        "hourglass_empty",
                        "hourglass_top",
                        "hourglass_bottom",
                        "hourglass_full"
                    ]

                    Timer {
                        running: refreshBtn.isLoading
                        repeat: true
                        interval: 300
                        onTriggered: refreshBtn.dotPhase = (refreshBtn.dotPhase + 1) % 4
                    }

                    Timer {
                        id: finishTimer
                        interval: 1200
                        onTriggered: refreshBtn.isLoading = false
                    }

                    onClicked: {
                        if (isLoading) return;
                        isLoading = true;
                        dotPhase = 0;
                        Wallpapers.refreshWallpapers();
                        finishTimer.start();
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            visible: localWalls.count > 0

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                id: localWalls

                model: {
                    const walls = Wallpapers.list;
                    const baseDir = Paths.wallsdir;
                    const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                    const categories = {};
                    const list = [];
                    for (const w of walls) {
                        if (w.parentDir !== baseDir && w.parentDir !== liveDir) {
                            const category = Wallpapers.getCategoryFor(w);
                            if (category && (!(category in categories) || categories[category].name.localeCompare(w.name) > 0))
                                categories[category] = w;
                        } else {
                            list.push(w);
                        }
                    }
                    list.push(...Object.values(categories));
                    list.sort((a, b) => ((a.parentDir === baseDir || a.parentDir === liveDir) - (b.parentDir === baseDir || b.parentDir === liveDir)) || a.name.localeCompare(b.name));
                    while (list.length < Config.nexus.wallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property FileSystemEntry modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    source: {
                        if (!modelData) return "";
                        let path = String(modelData.path);
                        if (path.match(/\.(mp4|mkv|webm|avi|mov)$/i)) {
                            let parts = path.split("/");
                            let homeDir = "/" + parts[1] + "/" + parts[2];
                            let fileName = parts[parts.length - 1];
                            return homeDir + "/.cache/caelestia/live_thumbs/" + fileName + ".jpg";
                        }
                        return path;
                    }
                    formatIcon: {
                        if (!modelData) return "";
                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) {
                            return "folder";
                        }
                        return String(modelData.path).match(/\.(mp4|mkv|webm|avi|mov)$/i) ? "smart_display" : "image";
                    }
                    formatText: {
                        if (!modelData) return "";
                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) return "";
                        let path = String(modelData.path);
                        let props = Wallpapers.propertiesCache[path];
                        if (props) {
                            let parts = props.split(", ");
                            if (parts.length >= 2) return parts[1];
                        }
                        return path.split(".").pop().toUpperCase();
                    }
                    fpsText: {
                        if (!modelData) return "";
                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) return "";
                        let path = String(modelData.path);
                        let props = Wallpapers.propertiesCache[path];
                        if (props) {
                            let parts = props.split(", ");
                            if (parts.length === 3) return parts[2];
                        }
                        return "";
                    }
                    resText: {
                        if (!modelData) return "";
                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) return "";
                        let path = String(modelData.path);
                        let props = Wallpapers.propertiesCache[path];
                        if (props) {
                            let parts = props.split(", ");
                            return parts[0];
                        }
                        return "";
                    }
                    text: {
                        if (!modelData)
                            return "";

                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) {
                            const category = Wallpapers.getCategoryFor(modelData);
                            return category.slice(0, 1).toUpperCase() + category.slice(1);
                        }
                        return modelData.name;
                    }
                    onClicked: {
                        const liveDir = Quickshell.env("CAELESTIA_LIVE_WALLPAPERS_DIR") || (Paths.wallsdir.substring(0, Paths.wallsdir.lastIndexOf('/')) + "/Live-Wallpapers");
                        if (modelData.parentDir !== Paths.wallsdir && modelData.parentDir !== liveDir) {
                            root.nState.selectedWallpaperCategory = Wallpapers.getCategoryFor(modelData);
                            root.nState.openSubPage(2); // Category page
                        } else {
                            Wallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            asynchronous: true
            active: localWalls.count === 0
            visible: active

            sourceComponent: StyledRect {
                color: Colours.tPalette.m3surfaceContainer
                radius: Tokens.rounding.extraLarge
                implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

                ColumnLayout {
                    id: noWallsLayout

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("No local wallpapers found")
                        color: Colours.palette.m3outline
                        font: Tokens.font.title.small
                    }
                }
            }
        }
    }
}
