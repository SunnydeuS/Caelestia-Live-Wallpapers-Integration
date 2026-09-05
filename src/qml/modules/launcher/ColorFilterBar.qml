pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.modules.nexus

StyledRect {
    id: root

    readonly property var colorPalette: [
        { id: "red", name: qsTr("Red"), hex: "#E53935" },
        { id: "orange", name: qsTr("Orange"), hex: "#FB8C00" },
        { id: "yellow", name: qsTr("Yellow"), hex: "#FDD835" },
        { id: "green", name: qsTr("Green"), hex: "#4CAF50" },
        { id: "blue", name: qsTr("Blue"), hex: "#2196F3" },
        { id: "purple", name: qsTr("Purple"), hex: "#9C27B0" },
        { id: "pink", name: qsTr("Pink"), hex: "#EC407A" },
        { id: "white", name: qsTr("White"), hex: "#FFFFFF" },
        { id: "black", name: qsTr("Black"), hex: "#1A1A1A" }
    ]

    readonly property string activeColorName: {
        if (!Wallpapers.colorFilter || Wallpapers.colorFilter === "")
            return qsTr("All");
        for (let i = 0; i < colorPalette.length; i++) {
            if (colorPalette[i].id === Wallpapers.colorFilter)
                return colorPalette[i].name;
        }
        return Wallpapers.colorFilter;
    }

    color: Qt.rgba(Colours.palette.m3surfaceContainerHigh.r, Colours.palette.m3surfaceContainerHigh.g, Colours.palette.m3surfaceContainerHigh.b, 0.9)
    radius: Tokens.rounding.large

    implicitWidth: layoutRow.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: 38

    Row {
        id: layoutRow
        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        // Active filter badge & reset action
        StyledRect {
            id: labelBadge
            anchors.verticalCenter: parent.verticalCenter
            color: Wallpapers.colorFilter !== "" ? Colours.palette.m3secondaryContainer : "transparent"
            radius: Tokens.rounding.medium
            implicitWidth: badgeContent.implicitWidth + (Wallpapers.colorFilter !== "" ? Tokens.padding.medium : Tokens.padding.small)
            implicitHeight: 26

            Row {
                id: badgeContent
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: "palette"
                    fontStyle: Tokens.font.icon.small
                    color: Wallpapers.colorFilter !== "" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.activeColorName
                    font: Tokens.font.label.small
                    color: Wallpapers.colorFilter !== "" ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                MaterialIcon {
                    visible: Wallpapers.colorFilter !== ""
                    text: "close"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSecondaryContainer
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StateLayer {
                id: badgeLayer
                radius: parent.radius
                disabled: Wallpapers.colorFilter === ""
                onClicked: Wallpapers.colorFilter = ""
            }
        }

        // Subtle vertical separator
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Colours.palette.m3outlineVariant
        }

        // Color pills row
        Row {
            id: pillsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.small

            Repeater {
                model: root.colorPalette

                delegate: Item {
                    id: pillWrapper
                    required property var modelData

                    readonly property bool isSelected: Wallpapers.colorFilter === modelData.id
                    readonly property bool isHovered: swatchState.containsMouse

                    width: isSelected ? 30 : 22
                    height: 22

                    Behavior on width {
                        Anim {
                            duration: 150
                            type: Anim.DefaultEffects
                        }
                    }

                    Rectangle {
                        id: swatch
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        radius: Tokens.rounding.small
                        color: pillWrapper.modelData.hex
                        scale: pillWrapper.isHovered ? 1.15 : (pillWrapper.isSelected ? 1.08 : 1.0)

                        border.width: pillWrapper.isSelected ? 2 : (pillWrapper.modelData.id === "black" || pillWrapper.modelData.id === "white" ? 1 : 0)
                        border.color: pillWrapper.isSelected ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant

                        Behavior on scale {
                            Anim {
                                duration: 150
                                type: Anim.DefaultEffects
                            }
                        }

                        StateLayer {
                            id: swatchState
                            radius: parent.radius
                            onClicked: {
                                if (Wallpapers.colorFilter === pillWrapper.modelData.id) {
                                    Wallpapers.colorFilter = "";
                                } else {
                                    Wallpapers.colorFilter = pillWrapper.modelData.id;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Subtle vertical separator
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: 18
            color: Colours.palette.m3outlineVariant
        }

        // Settings gear button
        StyledRect {
            id: settingsBtn
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 26
            implicitHeight: 26
            radius: Tokens.rounding.full
            color: settingsState.containsMouse ? Colours.palette.m3secondaryContainer : "transparent"

            MaterialIcon {
                anchors.centerIn: parent
                text: "settings"
                fontStyle: Tokens.font.icon.small
                color: settingsState.containsMouse ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
            }

            StateLayer {
                id: settingsState
                radius: parent.radius
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    try {
                        const ss = ShellState.forActive();
                        if (ss) ss.launcher = false;
                    } catch(e) {}
                    WindowFactory.openWallpaperSettings();
                }
            }
        }
    }
}
