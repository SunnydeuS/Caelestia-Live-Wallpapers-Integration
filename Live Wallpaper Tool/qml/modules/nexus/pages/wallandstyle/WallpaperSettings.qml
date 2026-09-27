import QtQuick
import QtQuick.Layouts
import Caelestia.Config
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

        SectionHeader {
            first: true
            text: qsTr("Animations")
        }

        ToggleRow {
            first: true
            text: qsTr("Enable animations")
            subtext: qsTr("Animate transitions when the wallpaper changes")
            checked: !Wallpapers.disableAnimations
            onToggled: {
                Wallpapers.disableAnimations = !checked;
                Wallpapers.saveSettings();
            }
        }

        SliderRow {
            icon: "timer"
            label: qsTr("Animation duration")
            valueLabel: qsTr("%1 ms").arg(Wallpapers.animationDuration)
            enabled: !Wallpapers.disableAnimations
            value: (Wallpapers.animationDuration - 1) / 1999
            onMoved: v => {
                Wallpapers.animationDuration = Math.round(1 + v * 1999);
                Wallpapers.saveSettings();
            }
        }

        SliderRow {
            last: true
            icon: "speed"
            label: qsTr("Max FPS")
            valueLabel: Wallpapers.maxFps === 0 ? qsTr("Original") : qsTr("%1 FPS").arg(Wallpapers.maxFps)
            value: {
                const options = [0, 24, 30, 60];
                const idx = Math.max(0, options.indexOf(Wallpapers.maxFps));
                return idx / (options.length - 1);
            }
            onMoved: v => {
                const options = [0, 24, 30, 60];
                Wallpapers.maxFps = options[Math.round(v * (options.length - 1))];
                Wallpapers.saveSettings();
                Wallpapers.refreshWallpapers();
            }
        }

        SectionHeader {
            text: qsTr("Behavior")
        }

        ToggleRow {
            first: true
            text: qsTr("Smart pause")
            subtext: qsTr("Pause the wallpaper using the rules below")
            checked: Wallpapers.behaviorEnabled
            onToggled: {
                Wallpapers.behaviorEnabled = checked;
                Wallpapers.saveSettings();
            }
        }

        ToggleRow {
            text: qsTr("Pause on fullscreen")
            subtext: qsTr("Pause when a fullscreen window is focused")
            disabled: !Wallpapers.behaviorEnabled
            checked: Wallpapers.pauseOnFullscreen
            onToggled: {
                Wallpapers.pauseOnFullscreen = checked;
                Wallpapers.saveSettings();
            }
        }

        ToggleRow {
            text: qsTr("Pause on game mode")
            subtext: qsTr("Pause while game mode is enabled")
            disabled: !Wallpapers.behaviorEnabled
            checked: Wallpapers.pauseOnGameMode
            onToggled: {
                Wallpapers.pauseOnGameMode = checked;
                Wallpapers.saveSettings();
            }
        }

        ToggleRow {
            text: qsTr("Battery limit")
            subtext: qsTr("Pause below a battery percentage while discharging")
            disabled: !Wallpapers.behaviorEnabled
            checked: Wallpapers.batteryLimitEnabled
            onToggled: {
                Wallpapers.batteryLimitEnabled = checked;
                Wallpapers.saveSettings();
            }
        }

        SliderRow {
            last: true
            icon: "battery_android_4"
            label: qsTr("Battery threshold")
            valueLabel: qsTr("%1%").arg(Wallpapers.batteryLimit)
            enabled: Wallpapers.behaviorEnabled && Wallpapers.batteryLimitEnabled
            value: Wallpapers.batteryLimit / 100
            onMoved: v => {
                Wallpapers.batteryLimit = Math.round(v * 100);
                Wallpapers.saveSettings();
            }
        }
    }
}
