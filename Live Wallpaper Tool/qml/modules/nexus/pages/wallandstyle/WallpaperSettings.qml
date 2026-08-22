pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper settings")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Energy Settings
        SectionHeader {
            first: true
            text: qsTr("Energy settings")
        }

        ToggleRow {
            first: true
            last: !Wallpapers.batteryLimitEnabled
            text: qsTr("Battery saver")
            subtext: qsTr("Pause live wallpapers when battery is low")
            checked: Wallpapers.batteryLimitEnabled
            onToggled: {
                Wallpapers.batteryLimitEnabled = checked;
                Wallpapers.saveSettings();
            }
        }

        StepperRow {
            last: true
            visible: Wallpapers.batteryLimitEnabled
            label: qsTr("Battery Limit")
            subtext: qsTr("Pause live wallpapers when battery is at or below %1%").arg(Wallpapers.batteryLimit)
            value: Wallpapers.batteryLimit
            from: 5
            to: 100
            stepSize: 5
            onMoved: v => {
                Wallpapers.batteryLimit = v;
                Wallpapers.saveSettings();
            }
        }

        // Playback Behavior
        SectionHeader {
            text: qsTr("Playback behavior")
        }

        ToggleRow {
            first: true
            text: qsTr("Pause on fullscreen")
            subtext: qsTr("Pause playback when an application is fullscreen")
            checked: Wallpapers.pauseOnFullscreen
            onToggled: {
                Wallpapers.pauseOnFullscreen = checked;
                Wallpapers.saveSettings();
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Pause on Game Mode")
            subtext: qsTr("Pause playback when Game Mode is active")
            checked: Wallpapers.pauseOnGameMode
            onToggled: {
                Wallpapers.pauseOnGameMode = checked;
                Wallpapers.saveSettings();
            }
        }
    }
}
