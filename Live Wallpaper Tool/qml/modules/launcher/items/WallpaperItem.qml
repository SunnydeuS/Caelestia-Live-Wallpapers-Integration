import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import QtMultimedia

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    property string formatIcon: String(root.modelData.path).match(/\.(mp4|mkv|webm|avi|mov)$/i) ? "smart_display" : "image"
    property string formatText: {
        let path = String(root.modelData.path);
        let props = Wallpapers.propertiesCache[path];
        if (props) {
            let parts = props.split(", ");
            if (parts.length >= 2) return parts[1].trim();
        }
        return path.split(".").pop().toUpperCase();
    }
    property string fpsText: {
        let path = String(root.modelData.path);
        let props = Wallpapers.propertiesCache[path];
        if (props) {
            let parts = props.split(", ");
            if (parts.length === 3) return parts[2].trim();
        }
        return "";
    }
    property string resText: {
        let path = String(root.modelData.path);
        let props = Wallpapers.propertiesCache[path];
        if (props) {
            let parts = props.split(", ");
            return parts[0].trim();
        }
        let fileName = path.split("/").pop();
        return fileName.substring(0, fileName.lastIndexOf(".")) || fileName;
    }

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
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

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (root.modelData.path && root.modelData.path.match(/\.(mp4|mkv|webm|avi|mov)$/i))
                    return vidComp;
                return imgComp;
            }
        }

        Component {
            id: imgComp
            CachingImage {
                anchors.fill: parent
                path: root.modelData.path
                smooth: !root.PathView.view.moving
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
                }
            }
        }

        Component {
            id: vidComp
            Item {
                anchors.fill: parent

                CachingImage {
                    id: thumb
                    anchors.fill: parent
                    
                    path: {
                        if (!root.modelData.path.match(/\.(mp4|mkv|webm|avi|mov)$/i))
                            return root.modelData.path;
                            
                        let parts = root.modelData.path.split("/");
                        let homeDir = "/" + parts[1] + "/" + parts[2];
                        let fileName = parts[parts.length - 1];
                        return homeDir + "/.cache/caelestia/live_thumbs/" + fileName + ".jpg";
                    }
                    
                    smooth: !root.PathView.view.moving
                    sourceSize: {
                        const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                        return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
                    }
                }
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
