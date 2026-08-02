pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property alias source: img.source
    property alias text: label.text
    property alias radius: imgWrapper.radius
    property alias imgHeight: imgWrapper.implicitHeight
    property bool fillLabel: true
    property string formatText: ""
    property string formatIcon: ""
    property string fpsText: ""
    property string resText: ""

    signal clicked

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.small

        StyledClippingRect {
            id: imgWrapper

            Layout.fillWidth: true
            implicitHeight: width
            radius: Tokens.rounding.largeIncreased
            color: Colours.tPalette.m3surfaceContainer

            Loader {
                anchors.centerIn: parent

                opacity: img.status === Image.Ready ? 0 : 1
                active: opacity > 0

                sourceComponent: StyledRect {
                    implicitWidth: loadingIndicator.implicitSize + Tokens.padding.large * 2
                    implicitHeight: loadingIndicator.implicitSize + Tokens.padding.large * 2

                    color: Colours.palette.m3primaryContainer
                    radius: Tokens.rounding.full

                    LoadingIndicator {
                        id: loadingIndicator

                        anchors.centerIn: parent
                        containsIcon: true
                        implicitSize: Math.min(imgWrapper.width, imgWrapper.height) * 0.3
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Image {
                id: img

                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                sourceSize: {
                    const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                    return Qt.size(width * dpr, height * dpr);
                }
                retainWhileLoading: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            StyledRect {
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

            StyledRect {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.margins: Tokens.spacing.small
                
                visible: root.resText !== ""
                color: Qt.rgba(Colours.palette.m3surfaceContainer.r, Colours.palette.m3surfaceContainer.g, Colours.palette.m3surfaceContainer.b, 0.8)
                radius: Tokens.rounding.small
                implicitWidth: resLayout.implicitWidth + Tokens.padding.small * 2
                implicitHeight: resLayout.implicitHeight + Tokens.padding.extraSmall * 2

                Row {
                    id: resLayout
                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall
                    
                    MaterialIcon {
                        text: "aspect_ratio"
                        fontStyle: Tokens.font.icon.small
                        color: Colours.palette.m3onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.resText
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        StyledText {
            id: label

            Layout.bottomMargin: Tokens.padding.small
            Layout.fillWidth: true
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.builders.small.weight(Font.Medium).build()
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    StateLayer {
        anchors.bottomMargin: root.fillLabel ? 0 : layout.implicitHeight - imgWrapper.implicitHeight
        onClicked: root.clicked()
    }
}
