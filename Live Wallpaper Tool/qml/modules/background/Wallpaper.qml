pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils
import QtMultimedia
import Quickshell.Services.UPower

Item {
    id: root

    property string source: Wallpapers.current
    property var current
    property bool completed

    onSourceChanged: {
        if (!source)
            current = null;
        else {
            if (source.match(/\.(mp4|mkv|webm|avi|mov)$/i)) {
                current = videoComp.createObject(this, {
                    path: source
                });
            } else {
                current = imgComp.createObject(this, {
                    path: source
                });
            }
        }
    }

    Component.onCompleted: {
        completed = true;
        if (!current && source) {
            Qt.callLater(() => {
                if (!current && source) {
                    if (source.match(/\.(mp4|mkv|webm|avi|mov)$/i)) {
                        current = videoComp.createObject(this, {
                            path: source
                        });
                    } else {
                        current = imgComp.createObject(this, {
                            path: source
                        });
                    }
                }
            });
        }
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    Component {
        id: videoComp

        Item {
            id: vidRoot
            property string path
            property bool isReady: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.playbackState === MediaPlayer.PlayingState || player.playbackState === MediaPlayer.PausedState
            anchors.fill: parent
            opacity: 0

            onIsReadyChanged: {
                if (isReady && opacity === 0) {
                    animVid.start();
                }
            }

            MediaPlayer {
                id: player
                source: vidRoot.path ? "file://" + vidRoot.path : ""
                videoOutput: videoOutput
                audioOutput: null
                loops: MediaPlayer.Infinite

                property bool isCovered: {
                    try {
                        if (Wallpapers.showPreview) return false;

                        if (typeof GameMode !== 'undefined' && GameMode && GameMode.enabled) return true;
                        
                        if (UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery) {
                            if (UPower.displayDevice.state === UPowerDeviceState.Discharging && UPower.displayDevice.percentage <= 0.40) {
                                return true;
                            }
                        }

                        if (typeof Hypr !== 'undefined' && Hypr && Hypr.activeToplevel && Hypr.activeToplevel.lastIpcObject && Hypr.activeToplevel.lastIpcObject.fullscreen) {
                            const winClass = (Hypr.activeToplevel.lastIpcObject.class || "").toLowerCase();
                            const browsers = ["firefox", "brave", "chromium", "chrome", "zen", "thorium", "vivaldi", "opera", "floorp", "waterfox", "librewolf", "edge"];
                            if (browsers.some(b => winClass.includes(b))) return false;
                            return true;
                        }
                        return false;
                    } catch (e) {
                        return false;
                    }
                }

                onIsCoveredChanged: {
                    if (isCovered) {
                        player.pause();
                    } else if (root.current === vidRoot) {
                        player.play();
                    }
                }

                onErrorOccurred: (error, errorString) => {
                    if (error !== MediaPlayer.NoError && vidRoot.path) {
                        let p = vidRoot.path;
                        vidRoot.path = "";
                        Qt.callLater(() => {
                            vidRoot.path = p;
                            if (!player.isCovered) player.play();
                        });
                    }
                }

                Component.onCompleted: {
                    play();
                    if (isCovered) {
                        Qt.callLater(() => {
                            if (isCovered) pause();
                        });
                    }
                }
                onPlaybackStateChanged: {
                    if (playbackState === MediaPlayer.PlayingState) {
                        animVid.start();
                    }
                }
                onMediaStatusChanged: {
                    if (mediaStatus === MediaPlayer.LoadedMedia || mediaStatus === MediaPlayer.BufferedMedia) {
                        animVid.start();
                    }
                }
            }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
            }

            NumberAnimation {
                id: animVid
                target: vidRoot
                property: "opacity"
                duration: typeof Tokens !== 'undefined' && Tokens.anim ? Tokens.anim.durations.expressiveSlowEffects : 500
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== vidRoot && root.current?.isReady
                interval: typeof animVid !== 'undefined' ? animVid.duration : 500
                onTriggered: {
                    player.stop();
                    player.source = "";
                    vidRoot.destroy();
                }
            }
        }
    }

    Component {
        id: imgComp

        CachingImage {
            id: img

            property bool isReady: status === Image.Ready

            anchors.fill: parent
            opacity: 0

            onStatusChanged: {
                if (status === Image.Ready)
                    anim.start();
            }

            Anim on opacity {
                id: anim

                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            Timer {
                running: root.current !== img && root.current?.isReady
                interval: anim.duration || 500
                onTriggered: {
                    img.source = "";
                    img.destroy();
                }
            }
        }
    }
}
