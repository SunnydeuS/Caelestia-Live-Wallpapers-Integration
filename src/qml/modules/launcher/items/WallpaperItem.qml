import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    property string formatIcon: Wallpapers.isVideo(root.modelData.path) ? "smart_display" : "image"
    property string formatText: Wallpapers.getFormat(root.modelData.path)
    property string fpsText: Wallpapers.getFps(root.modelData.path)
    property string resText: Wallpapers.getResolution(root.modelData.path)

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            if (Colours.scheme === "dynamic" && root.modelData.path !== Wallpapers.actualCurrent)
                Wallpapers.previewColourLock = true;
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        visible: opacity > 0
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: Tokens.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }

        CachingImage {
            anchors.fill: parent
            path: Wallpapers.getThumb(root.modelData?.path ?? "")
            smooth: !root.PathView.view.moving
            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
            }
        }

        StyledRect {
            z: 2
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Tokens.spacing.small
            
            visible: root.formatText !== "" || root.formatIcon !== ""
            color: Qt.rgba(Colours.palette.m3surfaceContainer.r, Colours.palette.m3surfaceContainer.g, Colours.palette.m3surfaceContainer.b, 0.8)
            radius: Tokens.rounding.small
            implicitWidth: badgeLayout.implicitWidth + Tokens.padding.small * 2
            implicitHeight: badgeLayout.implicitHeight + Tokens.padding.extraSmall * 2

            Row {
                id: badgeLayout
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall
                
                MaterialIcon {
                    visible: root.formatIcon !== ""
                    text: root.formatIcon
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    visible: root.formatText !== ""
                    text: root.formatText
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        StyledRect {
            z: 2
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Tokens.spacing.small
            
            visible: root.fpsText !== ""
            color: Qt.rgba(Colours.palette.m3surfaceContainer.r, Colours.palette.m3surfaceContainer.g, Colours.palette.m3surfaceContainer.b, 0.8)
            radius: Tokens.rounding.small
            implicitWidth: fpsLayout.implicitWidth + Tokens.padding.small * 2
            implicitHeight: fpsLayout.implicitHeight + Tokens.padding.extraSmall * 2

            Row {
                id: fpsLayout
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall
                
                MaterialIcon {
                    text: "speed"
                    fontStyle: Tokens.font.icon.small
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: root.fpsText
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.resText
        font: Tokens.font.label.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
