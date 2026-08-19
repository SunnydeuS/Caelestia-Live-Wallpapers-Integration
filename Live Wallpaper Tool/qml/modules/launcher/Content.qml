pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge

    implicitWidth: Math.max(listWrapper.width + padding * 2, colorFilterLoader.item && colorFilterLoader.item.visible ? colorFilterLoader.item.implicitWidth + padding * 2 : 0)
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin + (wallpaperButtonsRow.visible ? wallpaperButtonsRow.implicitHeight + root.padding : 0) + (colorFilterLoader.item && colorFilterLoader.item.visible ? colorFilterLoader.item.implicitHeight - Tokens.spacing.small : 0)

    property real lastRandomTime: 0

    function selectRandomWallpaper(): void {
        const now = Date.now();
        if (now - lastRandomTime < 80)
            return;
        lastRandomTime = now;

        if (list.currentList && list.currentList.count > 0) {
            let count = list.currentList.count;
            let current = list.currentList.currentIndex;
            let randomIndex = current;
            if (count > 1) {
                while (randomIndex === current) {
                    randomIndex = Math.floor(Math.random() * count);
                }
            }
            list.currentList.currentIndex = randomIndex;
            list.currentList.positionViewAtIndex(randomIndex, PathView.SnapPosition);
        } else {
            Wallpapers.setRandom();
        }
    }

    function triggerRefresh(): void {
        if (refreshBtn.isLoading)
            return;
        refreshBtn.isLoading = true;
        refreshBtn.dotPhase = 0;
        Wallpapers.refreshWallpapers();
        finishTimer.start();
    }

    Loader {
        id: colorFilterLoader
        active: list.showWallpapers
        asynchronous: true
        anchors.bottom: listWrapper.top
        anchors.bottomMargin: -18
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: ColorFilterBar {}
    }

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: wallpaperButtonsRow.visible ? wallpaperButtonsRow.top : search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    Row {
        id: wallpaperButtonsRow
        visible: list.showWallpapers
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.medium

        IconTextButton {
            icon: "collections"
            text: qsTr("All")
            isToggle: true
            checked: Wallpapers.filterMode === 2
            onClicked: Wallpapers.filterMode = 2
        }
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
            icon: "shuffle"
            text: qsTr("Random")
            onClicked: root.selectRandomWallpaper()
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

            onClicked: root.triggerRefresh()
        }
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        Keys.onLeftPressed: event => {
            if (list.showWallpapers) {
                Wallpapers.cycleFilterMode(true);
                event.accepted = true;
            }
        }

        Keys.onRightPressed: event => {
            if (list.showWallpapers) {
                Wallpapers.cycleFilterMode(false);
                event.accepted = true;
            }
        }

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onBacktabPressed: event => {
            if (list.showWallpapers) {
                Wallpapers.cycleColorFilter(false);
                event.accepted = true;
            } else if (GlobalConfig.launcher.vimKeybinds) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Keys.onTabPressed: event => {
            if (list.showWallpapers) {
                if (event.modifiers & Qt.ShiftModifier) {
                    Wallpapers.cycleColorFilter(false);
                } else {
                    root.selectRandomWallpaper();
                }
                event.accepted = true;
            } else if (GlobalConfig.launcher.vimKeybinds) {
                if (event.modifiers & Qt.ShiftModifier) {
                    list.currentList?.decrementCurrentIndex();
                } else {
                    list.currentList?.incrementCurrentIndex();
                }
                event.accepted = true;
            }
        }

        Keys.onPressed: event => {
            if (list.showWallpapers) {
                if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_R) {
                    root.triggerRefresh();
                    event.accepted = true;
                    return;
                }
            }

            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            }
        }

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.screenState.launcher) {
                    search.text = "";
                    Wallpapers.colorFilter = "";
                }
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
