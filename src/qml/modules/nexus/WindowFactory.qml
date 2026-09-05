pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        nexusComp.createObject(parent ?? dummy, props);
    }

    function openWallpaperSettings(): void {
        const win = nexusComp.createObject(dummy);
        if (win && win.nexus) {
            win.nexus.nState.currentPageIdx = 0;
            win.nexus.nState.openSubPage(4);
        }
    }

    function openPage(pageIdx: int, subPageIdx: var): void {
        const win = nexusComp.createObject(dummy);
        if (win && win.nexus) {
            win.nexus.nState.currentPageIdx = pageIdx;
            if (subPageIdx !== undefined && subPageIdx >= 0) {
                win.nexus.nState.openSubPage(subPageIdx);
            }
        }
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            readonly property alias nexus: nexus

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: qsTr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
