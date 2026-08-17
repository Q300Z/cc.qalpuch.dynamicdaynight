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

    // Forced period override for preview mode ("" = automatic, "morning" | "noon" | "evening" | "night")
    property string forcedPeriod: ""

    // Automatically calculated period from system time and configuration
    readonly property string autoPeriod: TimeUtils.getCurrentPeriod(currentTime, root.configuration)

    // Currently active period: forced period if specified, otherwise the automatically calculated one
    readonly property string currentPeriod: forcedPeriod !== "" ? forcedPeriod : autoPeriod

    // Effective schedule for period boundaries
    readonly property var currentSchedule: TimeUtils.getEffectiveSchedule(currentTime, root.configuration)

    // Dynamic accent color: applied only if enabled in settings.
    // Uses autoPeriod (real temporal cycle) so forcedPeriod previews don't pollute global OS accent color.
    // Evaluates to undefined when disabled, yielding an invalid QColor to cleanly restore default system theme.
    accentColor: (root.configuration && root.configuration.DynamicAccentColor)
        ? Qt.color(TimeUtils.getAccentColorForPeriod(autoPeriod, root.configuration))
        : undefined

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

    // Declarative loading state: active until initial load completes or while active layer is loading
    loading: !initialLoadDone || (activeLayerIndex === 0 ? imageLayerA.status === Image.Loading : imageLayerB.status === Image.Loading)

    onAccentColorChanged: {
        console.log("[cc.qalpuch.dynamicdaynight] Dynamic accent color updated:", root.accentColor);
    }

    /**
     * Resolves default bundled image URL for a given period.
     * @param {string} period - 'morning', 'noon', 'evening', 'night'
     * @returns {url}
     */
    function getBundledImageSource(period) {
        switch (period) {
            case "morning":
                return Qt.resolvedUrl("../images/matin.png");
            case "noon":
                return Qt.resolvedUrl("../images/midi.png");
            case "evening":
                return Qt.resolvedUrl("../images/soir.png");
            case "night":
            default:
                return Qt.resolvedUrl("../images/nuit.png");
        }
    }

    /**
     * Localized display name for a period identifier.
     * @param {string} period - 'morning', 'noon', 'evening', 'night'
     * @returns {string}
     */
    function getPeriodDisplayName(period) {
        switch (period) {
            case "morning":
                return i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning");
            case "noon":
                return i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon");
            case "evening":
                return i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening");
            case "night":
                return i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night");
            default:
                return "";
        }
    }

    // Contextual actions providing a complete desktop right-click menu
    contextualActions: [
        PlasmaCore.Action {
            text: {
                if (root.forcedPeriod !== "") {
                    return i18nd(
                        "plasma_wallpaper_cc.qalpuch.dynamicdaynight",
                        "Previewing: %1 (Forced)",
                        root.getPeriodDisplayName(root.forcedPeriod)
                    );
                }
                const range = TimeUtils.getPeriodRange(root.autoPeriod, root.currentSchedule);
                return i18nd(
                    "plasma_wallpaper_cc.qalpuch.dynamicdaynight",
                    "Current cycle: %1 (%2 - %3)",
                    root.getPeriodDisplayName(root.autoPeriod),
                    TimeUtils.formatMinutes(range.start),
                    TimeUtils.formatMinutes(range.end)
                );
            }
            icon.name: root.forcedPeriod !== "" ? "document-preview" : TimeUtils.getPeriodIcon(root.autoPeriod)
            onTriggered: {
                root.scheduleNextTick();
                root.updateWallpaper(true);
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Preview: %1", root.getPeriodDisplayName("morning"))
            icon.name: "weather-sunset-up"
            checkable: true
            checked: root.forcedPeriod === "morning"
            onTriggered: {
                root.forcedPeriod = (root.forcedPeriod === "morning") ? "" : "morning";
                if (root.forcedPeriod === "") {
                    root.scheduleNextTick();
                }
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Preview: %1", root.getPeriodDisplayName("noon"))
            icon.name: "weather-clear"
            checkable: true
            checked: root.forcedPeriod === "noon"
            onTriggered: {
                root.forcedPeriod = (root.forcedPeriod === "noon") ? "" : "noon";
                if (root.forcedPeriod === "") {
                    root.scheduleNextTick();
                }
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Preview: %1", root.getPeriodDisplayName("evening"))
            icon.name: "weather-sunset-down"
            checkable: true
            checked: root.forcedPeriod === "evening"
            onTriggered: {
                root.forcedPeriod = (root.forcedPeriod === "evening") ? "" : "evening";
                if (root.forcedPeriod === "") {
                    root.scheduleNextTick();
                }
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Preview: %1", root.getPeriodDisplayName("night"))
            icon.name: "weather-clear-night"
            checkable: true
            checked: root.forcedPeriod === "night"
            onTriggered: {
                root.forcedPeriod = (root.forcedPeriod === "night") ? "" : "night";
                if (root.forcedPeriod === "") {
                    root.scheduleNextTick();
                }
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Resume automatic cycle")
            icon.name: "media-playback-start"
            enabled: root.forcedPeriod !== ""
            onTriggered: {
                root.forcedPeriod = "";
                root.scheduleNextTick();
            }
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Update Dynamic Wallpaper")
            icon.name: "view-refresh"
            onTriggered: {
                root.scheduleNextTick();
                root.updateWallpaper(true);
            }
        }
    ]

    // Crossfade layer A and B
    Item {
        id: imageContainer
        anchors.fill: parent

        // Map fill mode integer config (0: Stretch, 1: PreserveAspectCrop, 2: PreserveAspectFit)
        readonly property int resolvedFillMode: {
            const mode = (root.configuration && root.configuration.FillMode !== undefined) ? root.configuration.FillMode : 1;
            switch (mode) {
                case 0:  return Image.Stretch;
                case 2:  return Image.PreserveAspectFit;
                case 1:
                default: return Image.PreserveAspectCrop;
            }
        }

        readonly property int transitionDuration: (root.configuration && root.configuration.TransitionDuration !== undefined)
            ? root.configuration.TransitionDuration
            : 1500

        Image {
            id: imageLayerA
            anchors.fill: parent
            fillMode: imageContainer.resolvedFillMode
            asynchronous: true
            cache: true
            opacity: 1.0
            smooth: true
            mipmap: true

            onStatusChanged: {
                if (status === Image.Ready && root.activeLayerIndex === 1 && String(imageLayerA.source) !== "") {
                    imageLayerA.opacity = 1.0;
                    imageLayerB.opacity = 0.0;
                    root.activeLayerIndex = 0;
                } else if (status === Image.Error) {
                    console.warn("[cc.qalpuch.dynamicdaynight] Failed to load wallpaper: " + source + " - Falling back to default bundled image.");
                    const fallbackUrl = root.getBundledImageSource(root.currentPeriod);
                    if (source !== fallbackUrl) {
                        source = fallbackUrl;
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: imageContainer.transitionDuration
                    easing.type: Easing.InOutQuad
                    onRunningChanged: {
                        if (!running && imageLayerA.opacity === 0.0) {
                            imageLayerA.source = "";
                        }
                    }
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

            onStatusChanged: {
                if (status === Image.Ready && root.activeLayerIndex === 0 && String(imageLayerB.source) !== "") {
                    imageLayerB.opacity = 1.0;
                    imageLayerA.opacity = 0.0;
                    root.activeLayerIndex = 1;
                } else if (status === Image.Error) {
                    console.warn("[cc.qalpuch.dynamicdaynight] Failed to load wallpaper: " + source + " - Falling back to default bundled image.");
                    const fallbackUrl = root.getBundledImageSource(root.currentPeriod);
                    if (source !== fallbackUrl) {
                        source = fallbackUrl;
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: imageContainer.transitionDuration
                    easing.type: Easing.InOutQuad
                    onRunningChanged: {
                        if (!running && imageLayerB.opacity === 0.0) {
                            imageLayerB.source = "";
                        }
                    }
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
            imageLayerB.source = "";
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
            if (imageLayerB.status === Image.Ready) {
                imageLayerB.opacity = 1.0;
                imageLayerA.opacity = 0.0;
                root.activeLayerIndex = 1;
            }
        } else {
            imageLayerA.source = nextUrl;
            if (imageLayerA.status === Image.Ready) {
                imageLayerA.opacity = 1.0;
                imageLayerB.opacity = 0.0;
                root.activeLayerIndex = 0;
            }
        }
    }

    /**
     * Reschedules dynamic timer tick according to exact remaining milliseconds
     * and refreshes current timestamp.
     */
    function scheduleNextTick() {
        root.currentTime = new Date();
        const nextDelay = Math.max(5000, TimeUtils.getMsUntilNextPeriod(root.currentTime, root.configuration));
        timeTicker.interval = nextDelay;
        timeTicker.restart();
    }

    // React to target image source changes
    onTargetImageSourceChanged: {
        root.updateWallpaper(false);
    }

    // Dynamic timer scheduled to trigger at the next period transition
    Timer {
        id: timeTicker
        interval: Math.max(5000, TimeUtils.getMsUntilNextPeriod(root.currentTime, root.configuration))
        running: true
        repeat: false
        onTriggered: {
            root.scheduleNextTick();
        }
    }

    // Heartbeat Watchdog Timer (30s interval) to detect system wake-up from suspend/sleep immediately
    property double lastHeartbeatTime: Date.now()

    Timer {
        id: heartbeatWatchdog
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            const now = Date.now();
            const elapsed = now - root.lastHeartbeatTime;
            root.lastHeartbeatTime = now;

            // If elapsed time > 45s, a system suspend or severe clock jump occurred
            if (elapsed > 45000) {
                console.log("[cc.qalpuch.dynamicdaynight] System wake/clock jump detected (" + elapsed + "ms elapsed). Resynchronizing.");
                root.scheduleNextTick();
            } else {
                root.currentTime = new Date();
            }
        }
    }

    // Refresh on system wake / application activation
    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive) {
                root.scheduleNextTick();
            }
        }
    }

    Component.onCompleted: {
        root.scheduleNextTick();
        root.updateWallpaper(true);
    }
}
