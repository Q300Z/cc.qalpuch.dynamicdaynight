/*
    SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "TimeUtils.js" as TimeUtils

WallpaperItem {
    id: root

    // Fill the screen area
    anchors.fill: parent

    // Currently active period: "morning" | "noon" | "evening" | "night"
    readonly property string currentPeriod: TimeUtils.getCurrentPeriod(currentTime, root.configuration)

    // Resolved source URL for the active period
    readonly property url targetImageSource: TimeUtils.getImageForPeriod(
        currentPeriod,
        root.configuration,
        (file) => Qt.resolvedUrl(file)
    )

    // Keep track of current system time
    property var currentTime: new Date()

    // Flag indicating whether the first wallpaper has loaded
    property bool initialLoadDone: false

    // Contextual action to manually refresh or inspect current period
    contextualActions: [
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Update Dynamic Wallpaper")
            icon.name: "view-refresh"
            onTriggered: {
                root.currentTime = new Date();
                root.updateWallpaper(true);
            }
        }
    ]

    // Crossfade layer A and B
    Item {
        id: imageContainer
        anchors.fill: parent

        // Map fill mode integer config to QtQuick Image fillMode enum
        readonly property int resolvedFillMode: {
            switch (root.configuration.FillMode) {
                case 1:  return Image.Stretch;
                case 3:  return Image.PreserveAspectFit;
                case 2:
                default: return Image.PreserveAspectCrop;
            }
        }

        Image {
            id: imageLayerA
            anchors.fill: parent
            fillMode: imageContainer.resolvedFillMode
            asynchronous: true
            cache: true
            opacity: 1.0
            smooth: true
            mipmap: true

            Behavior on opacity {
                NumberAnimation {
                    duration: root.configuration.TransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Image {
            id: imageLayerB
            anchors.fill: parent
            fillMode: imageContainer.resolvedFillMode
            asynchronous: true
            cache: true
            opacity: 0.0
            smooth: true
            mipmap: true

            Behavior on opacity {
                NumberAnimation {
                    duration: root.configuration.TransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Active layer tracker (0: layer A active, 1: layer B active)
    property int activeLayerIndex: 0

    /**
     * Updates wallpaper image sources with crossfade transition.
     * @param {boolean} force - Force update even if target URL has not changed
     */
    function updateWallpaper(force) {
        const nextUrl = root.targetImageSource;

        if (!root.initialLoadDone) {
            // First load: set image instantly without fade delay
            imageLayerA.source = nextUrl;
            imageLayerA.opacity = 1.0;
            imageLayerB.opacity = 0.0;
            root.activeLayerIndex = 0;
            root.initialLoadDone = true;
            return;
        }

        const currentActiveSource = (root.activeLayerIndex === 0) ? imageLayerA.source : imageLayerB.source;
        if (!force && String(currentActiveSource) === String(nextUrl)) {
            return;
        }

        if (root.activeLayerIndex === 0) {
            imageLayerB.source = nextUrl;
            imageLayerB.opacity = 1.0;
            imageLayerA.opacity = 0.0;
            root.activeLayerIndex = 1;
        } else {
            imageLayerA.source = nextUrl;
            imageLayerA.opacity = 1.0;
            imageLayerB.opacity = 0.0;
            root.activeLayerIndex = 0;
        }
    }

    // React to target image source changes
    onTargetImageSourceChanged: {
        root.updateWallpaper(false);
    }

    // Periodic timer to check for time transitions (every 30 seconds)
    Timer {
        id: timeTicker
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }

    Component.onCompleted: {
        root.currentTime = new Date();
        root.updateWallpaper(true);
        root.loading = false;
    }
}
