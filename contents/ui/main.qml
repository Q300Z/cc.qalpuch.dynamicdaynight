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

    // Occupe tout l'espace de l'écran
    anchors.fill: parent

    // Période forcée pour le mode prévisualisation ("" = automatique)
    property string forcedPeriod: ""

    // Période calculée automatiquement selon l'heure et la configuration
    readonly property string autoPeriod: TimeUtils.getCurrentPeriod(currentTime, root.configuration)

    // Période active (forcée si définie, sinon automatique)
    readonly property string currentPeriod: forcedPeriod !== "" ? forcedPeriod : autoPeriod

    // Plages horaires effectives de la journée
    readonly property var currentSchedule: TimeUtils.getEffectiveSchedule(currentTime, root.configuration)

    // URL résolue du fond d'écran pour la période active
    readonly property url targetImageSource: TimeUtils.getImageForPeriod(
        currentPeriod,
        root.configuration,
        (file) => Qt.resolvedUrl(file)
    )

    // Horloge système courante
    property var currentTime: new Date()

    // Indicateur du premier chargement initial
    property bool initialLoadDone: false

    // État de chargement déclaratif pour Plasma
    loading: !initialLoadDone || imageLayerA.status === Image.Loading || imageLayerB.status === Image.Loading

    /**
     * Retourne l'URL de l'image embarquée par défaut pour une période donnée.
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
     * Nom localisé de la période pour l'interface.
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

    // Actions contextuelles du menu clic droit sur le bureau
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

    // Conteneur de transition en fondu enchaîné (Crossfade)
    Item {
        id: imageContainer
        anchors.fill: parent

        // Mode de remplissage (0: Étiré, 1: Recadré/Zoom, 2: Ajusté)
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

        // Calque d'image A
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
                    console.warn("[cc.qalpuch.dynamicdaynight] Échec chargement : " + source + " - Repli sur l'image par défaut.");
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
                        if (!running && imageLayerA.opacity === 0.0 && root.activeLayerIndex === 1 && String(imageLayerA.source) !== String(root.targetImageSource)) {
                            imageLayerA.source = "";
                        }
                    }
                }
            }
        }

        // Calque d'image B
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
                    console.warn("[cc.qalpuch.dynamicdaynight] Échec chargement : " + source + " - Repli sur l'image par défaut.");
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
                        if (!running && imageLayerB.opacity === 0.0 && root.activeLayerIndex === 0 && String(imageLayerB.source) !== String(root.targetImageSource)) {
                            imageLayerB.source = "";
                        }
                    }
                }
            }
        }
    }

    // Index du calque actuellement affiché (0: Calque A, 1: Calque B)
    property int activeLayerIndex: 0

    /**
     * Met à jour les sources d'images et déclenche la transition fluide.
     */
    function updateWallpaper(force) {
        const nextUrl = root.targetImageSource;

        if (!root.initialLoadDone) {
            // Premier chargement immédiat sans délai de transition
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
     * Planifie le prochain réveil du minuteur selon le temps restant exact.
     */
    function scheduleNextTick() {
        root.currentTime = new Date();
        const nextDelay = Math.max(5000, TimeUtils.getMsUntilNextPeriod(root.currentTime, root.configuration));
        timeTicker.interval = nextDelay;
        timeTicker.restart();
    }

    // Déclenchement automatique lors d'un changement de source d'image
    onTargetImageSourceChanged: {
        root.updateWallpaper(false);
    }

    // Minuteur dynamique calculé pour la prochaine bascule horaire
    Timer {
        id: timeTicker
        interval: Math.max(5000, TimeUtils.getMsUntilNextPeriod(root.currentTime, root.configuration))
        running: true
        repeat: false
        onTriggered: {
            root.scheduleNextTick();
        }
    }

    // Watchdog de battement cardiaque (30s) pour détecter le réveil après mise en veille (suspend)
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

            // Détection d'un saut temporel > 45s (reprise après veille du système)
            if (elapsed > 45000) {
                console.log("[cc.qalpuch.dynamicdaynight] Réveil système détecté (" + elapsed + " ms). Resynchronisation.");
                root.scheduleNextTick();
            } else {
                root.currentTime = new Date();
            }
        }
    }

    // Rafraîchissement lors de l'activation de l'application / session Plasma
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
