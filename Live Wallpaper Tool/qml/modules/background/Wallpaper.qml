pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
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

    readonly property var shapes: Wallpapers.shapes || [MaterialShape.Circle, MaterialShape.Square, MaterialShape.Diamond, MaterialShape.ClamShell, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Cookie6Sided]

    property string source: Wallpapers.current
    property var current
    property bool completed
    property string previousThumb: ""

    function isVideoSource(path) {
        return typeof path === 'string' && path.match(/\.(mp4|mkv|webm|avi|mov)$/i);
    }

    function videoThumbSource(path) {
        if (!path || !isVideoSource(path))
            return "";

        const parts = String(path).split("/");
        if (parts.length < 3)
            return "";

        const homeDir = "/" + parts[1] + "/" + parts[2];
        const fileName = parts[parts.length - 1];
        return `${homeDir}/.cache/caelestia/live_thumbs/${fileName}.jpg`;
    }

    function createMediaForSource(path, placeholderThumb = "") {
        if (isVideoSource(path)) {
            return videoComp.createObject(root, {
                path: path,
                thumbnailSource: placeholderThumb || videoThumbSource(path)
            });
        }
        return imgComp.createObject(root, { path: path });
    }

    onSourceChanged: {
        if (!source) {
            if (current) {
                current.destroy();
            }
            current = null;
            previousThumb = "";
            return;
        }

        const isVideo = isVideoSource(source);
        if (current && current.isVideo === isVideo) {
            if (isVideo) {
                previousThumb = current.thumbnailSource || videoThumbSource(current.path) || "";
                current.path = source;
                current.thumbnailSource = previousThumb;
            } else {
                current.source = source;
            }
            return;
        }

        if (current) {
            previousThumb = current.thumbnailSource || (current.isVideo ? videoThumbSource(current.path) : current.source) || "";
            current.z = 0;
            current.opacity = 1;
            current.visible = true;
        }

        const newMedia = createMediaForSource(source, previousThumb);
        newMedia.z = 1;
        newMedia.opacity = 0;
        current = newMedia;
        previousThumb = "";
    }

    Component.onCompleted: {
        completed = true;
        if (!current && source) {
            Qt.callLater(() => {
                if (!current && source) {
                    current = createMediaForSource(source);
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
            property bool isVideo: true
            property string path
            property string thumbnailSource: ""
            property bool isReady: player.mediaStatus === MediaPlayer.LoadedMedia || player.mediaStatus === MediaPlayer.BufferedMedia || player.mediaStatus === MediaPlayer.BufferingMedia || player.playbackState === MediaPlayer.PlayingState || player.playbackState === MediaPlayer.PausedState
            readonly property real maxRadius: Math.sqrt(width * width + height * height)
            property real maskRadius: 0
            property int currentShape: root.shapes[Math.floor(Math.random() * root.shapes.length)] ?? MaterialShape.Circle
            anchors.fill: parent
            opacity: 0
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskSourceItem
            }

            function beginTransition() {
                if (!Wallpapers.animsEnabled) {
                    opacity = 1;
                    maskRadius = maxRadius;
                    return;
                }
                // When animations are enabled, set opacity immediately and let mask control visibility
                opacity = 1;
                currentShape = root.shapes[Math.floor(Math.random() * root.shapes.length)] ?? MaterialShape.Circle;
                maskRadius = 0;
                maskAnim.restart();
            }

            onIsReadyChanged: {
                if (isReady) {
                    thumbPreview.opacity = 0;
                    if (opacity === 0)
                        beginTransition();
                } else if (thumbnailSource) {
                    thumbPreview.opacity = 1;
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

                        // Master switch: if behavior is disabled, don't auto-pause
                        if (!Wallpapers.behaviorEnabled) return false;

                        if (Wallpapers.pauseOnGameMode && typeof GameMode !== 'undefined' && GameMode && GameMode.enabled) return true;
                        
                        if (Wallpapers.batteryLimitEnabled && Wallpapers.batteryLimit > 0 && UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery) {
                            if (UPower.displayDevice.state === UPowerDeviceState.Discharging && (UPower.displayDevice.percentage * 100) <= Wallpapers.batteryLimit) {
                                return true;
                            }
                        }

                        if (Wallpapers.pauseOnFullscreen && typeof Hypr !== 'undefined' && Hypr && Hypr.activeToplevel && Hypr.activeToplevel.lastIpcObject && Hypr.activeToplevel.lastIpcObject.fullscreen) {
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
                    if (vidRoot.path) {
                        player.source = "file://" + vidRoot.path;
                    }
                    if (!isCovered) play();
                    if (isCovered) {
                        Qt.callLater(() => {
                            if (isCovered) pause();
                        });
                    }
                }
                onPlaybackStateChanged: {
                    // Fade animation now handled by beginTransition() for M3Shapes effect
                }
                onMediaStatusChanged: {
                    // Fade animation now handled by beginTransition() for M3Shapes effect
                }
            }

            Item {
                id: maskWrapper
                anchors.fill: parent
                visible: true

                MaterialShape {
                    anchors.centerIn: parent
                    width: vidRoot.maxRadius * 2
                    height: vidRoot.maxRadius * 2
                    shape: vidRoot.currentShape
                    color: "white"
                    scale: vidRoot.maxRadius > 0 ? (vidRoot.maskRadius / vidRoot.maxRadius) : 0
                }
            }

            ShaderEffectSource {
                id: maskSourceItem
                sourceItem: maskWrapper
                anchors.fill: parent
                hideSource: true
                live: true
                visible: false
            }

            CachingImage {
                id: thumbPreview
                anchors.fill: parent
                path: vidRoot.thumbnailSource || ""
                visible: !!path && opacity > 0
                opacity: vidRoot.isReady ? 0 : 1
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true
                Behavior on opacity {
                    NumberAnimation {
                        duration: Math.max(1, Math.min(2000, Wallpapers.animationDuration || 500))
                        easing.type: Easing.InOutCubic
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
                duration: Math.max(1, Math.min(2000, Wallpapers.animationDuration || 500))
                from: 0
                to: 1
            }

            NumberAnimation {
                id: maskAnim
                target: vidRoot
                property: "maskRadius"
                duration: Math.max(1, Math.min(2000, Wallpapers.animationDuration || 500))
                from: 0
                to: vidRoot.maxRadius
                easing.type: Easing.InOutCubic
            }

            Timer {
                running: root.current !== vidRoot && root.current?.isReady
                interval: typeof maskAnim !== 'undefined' ? maskAnim.duration : 500
                onTriggered: {
                    player.stop();
                    player.source = "";
                    vidRoot.destroy();
                }
            }

            onPathChanged: {
                if (!path) {
                    player.stop();
                    player.source = "";
                    return;
                }

                const placeholder = root.previousThumb || root.videoThumbSource(path);
                root.previousThumb = "";
                thumbnailSource = placeholder || root.videoThumbSource(path);
                thumbPreview.opacity = 1;
                opacity = 0;

                if (player.source !== "file://" + path) {
                    player.stop();
                    player.source = "file://" + path;
                }

                if (!player.isCovered) {
                    player.play();
                }
            }
        }
    }

    Component {
        id: imgComp

        CachingImage {
            id: img

            property bool isVideo: false
            property bool isReady: status === Image.Ready
            readonly property real maxRadius: Math.sqrt(width * width + height * height)
            property real maskRadius: 0
            property int currentShape: root.shapes[Math.floor(Math.random() * root.shapes.length)] ?? MaterialShape.Circle

            anchors.fill: parent
            opacity: 0
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: maskSourceItem
            }

            function beginTransition() {
                if (!Wallpapers.animsEnabled) {
                    opacity = 1;
                    maskRadius = maxRadius;
                    return;
                }
                // When animations are enabled, set opacity immediately and let mask control visibility
                opacity = 1;
                currentShape = root.shapes[Math.floor(Math.random() * root.shapes.length)] ?? MaterialShape.Circle;
                maskRadius = 0;
                maskAnim.restart();
            }

            onStatusChanged: {
                if (status === Image.Ready)
                    beginTransition();
            }

            Item {
                id: maskWrapper
                anchors.fill: parent
                visible: true

                MaterialShape {
                    anchors.centerIn: parent
                    width: img.maxRadius * 2
                    height: img.maxRadius * 2
                    shape: img.currentShape
                    color: "white"
                    scale: img.maxRadius > 0 ? (img.maskRadius / img.maxRadius) : 0
                }
            }

            ShaderEffectSource {
                id: maskSourceItem
                sourceItem: maskWrapper
                anchors.fill: parent
                hideSource: true
                live: true
                visible: false
            }

            Anim on opacity {
                id: anim

                type: Anim.SlowEffects
                running: false
                from: 0
                to: 1
            }

            NumberAnimation {
                id: maskAnim
                target: img
                property: "maskRadius"
                duration: Math.max(1, Math.min(2000, Wallpapers.animationDuration || 500))
                from: 0
                to: img.maxRadius
                easing.type: Easing.InOutCubic
            }

            Timer {
                running: root.current !== img && root.current?.isReady
                interval: maskAnim.duration || 500
                onTriggered: {
                    img.source = "";
                    img.destroy();
                }
            }
        }
    }
}
