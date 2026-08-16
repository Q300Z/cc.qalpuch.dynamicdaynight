/*
    SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts as Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "TimeUtils.js" as TimeUtils

Layouts.ColumnLayout {
    id: root

    // Properties and signals expected by KDE Plasma 6 kcm_wallpaper
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout
    property alias formLayout: innerFormLayout

    signal configurationChanged()

    Layouts.Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    // Automatic calculation option
    property alias cfg_AutoSchedule: autoScheduleCheckBox.checked

    // Manual schedule time slot bindings
    property alias cfg_MorningHour: morningHourSpin.value
    property alias cfg_MorningMinute: morningMinuteSpin.value

    property alias cfg_NoonHour: noonHourSpin.value
    property alias cfg_NoonMinute: noonMinuteSpin.value

    property alias cfg_EveningHour: eveningHourSpin.value
    property alias cfg_EveningMinute: eveningMinuteSpin.value

    property alias cfg_NightHour: nightHourSpin.value
    property alias cfg_NightMinute: nightMinuteSpin.value

    // Image path bindings
    property alias cfg_MorningImage: morningCard.pathText
    property alias cfg_NoonImage: noonCard.pathText
    property alias cfg_EveningImage: eveningCard.pathText
    property alias cfg_NightImage: nightCard.pathText

    // Behavior & Display settings
    property alias cfg_TransitionDuration: transitionSpin.value
    property alias cfg_FillMode: fillModeCombo.currentIndex

    // Real-time solar preview calculation for today based on system timezone/location
    readonly property var currentSolarSchedule: {
        const d = new Date();
        const sys = TimeUtils.getSystemCoordinates();
        return TimeUtils.calculateSolarSchedule(d, sys.lat, sys.lon);
    }

    /**
     * Resets all parameters to their initial factory default values.
     */
    function resetToDefaults() {
        autoScheduleCheckBox.checked = true;

        morningHourSpin.value = 6;
        morningMinuteSpin.value = 0;
        noonHourSpin.value = 12;
        noonMinuteSpin.value = 0;
        eveningHourSpin.value = 18;
        eveningMinuteSpin.value = 0;
        nightHourSpin.value = 22;
        nightMinuteSpin.value = 0;

        morningCard.pathText = "";
        noonCard.pathText = "";
        eveningCard.pathText = "";
        nightCard.pathText = "";

        fillModeCombo.currentIndex = 1;
        transitionSpin.value = 1500;

        root.configurationChanged();
    }

    // Helper component for time slot spinboxes
    component TimeInputRow: Layouts.RowLayout {
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.SpinBox {
            id: hourSpin
            from: 0
            to: 23
            editable: true
            onValueModified: root.configurationChanged()
        }

        PlasmaComponents.Label {
            text: ":"
            font.bold: true
        }

        PlasmaComponents.SpinBox {
            id: minSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(value) {
                return (value < 10 ? "0" : "") + value;
            }
            onValueModified: root.configurationChanged()
        }
    }

    // Visual 16:9 preview card component for each wallpaper slot
    component WallpaperPreviewCard: Kirigami.AbstractCard {
        id: card

        property string periodTitle: ""
        property string periodIcon: ""
        property string defaultFileName: ""
        property string dialogTitle: ""
        property string pathText: ""

        readonly property bool isCustom: pathText.trim().length > 0

        readonly property url resolvedImageSource: {
            if (card.isCustom) {
                const trimmed = pathText.trim();
                return trimmed.startsWith("file://") ? trimmed : "file://" + trimmed;
            }
            return Qt.resolvedUrl("../images/" + defaultFileName);
        }

        readonly property string displayFileName: {
            if (card.isCustom) {
                const trimmed = pathText.trim();
                const lastSlash = Math.max(trimmed.lastIndexOf("/"), trimmed.lastIndexOf("\\"));
                return lastSlash >= 0 ? trimmed.substring(lastSlash + 1) : trimmed;
            }
            return defaultFileName + " (" + i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default") + ")";
        }

        Layouts.Layout.fillWidth: true
        Layouts.Layout.minimumWidth: Kirigami.Units.gridUnit * 12

        contentItem: Layouts.ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            // Top Header: Icon + Period Name + Status Badge
            Layouts.RowLayout {
                Layouts.Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: card.periodIcon
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                }

                PlasmaComponents.Label {
                    text: card.periodTitle
                    font.weight: Font.Bold
                    Layouts.Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                // Custom vs Default pill badge
                Kirigami.ShadowedRectangle {
                    radius: Kirigami.Units.smallSpacing
                    color: card.isCustom ? Kirigami.Theme.highlightColor : Kirigami.Theme.alternateBackgroundColor
                    opacity: card.isCustom ? 0.95 : 0.85
                    border.color: Kirigami.Theme.separatorColor
                    border.width: 1

                    implicitWidth: badgeLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                    implicitHeight: badgeLabel.implicitHeight + Kirigami.Units.smallSpacing / 2

                    PlasmaComponents.Label {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: card.isCustom ? i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Custom") : i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: card.isCustom ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                    }
                }
            }

            // 16:9 Thumbnail Image with rounded corners and border
            Kirigami.ShadowedRectangle {
                id: thumbnailFrame
                Layouts.Layout.fillWidth: true
                Layouts.Layout.preferredHeight: Math.round(width * 9 / 16)
                Layouts.Layout.minimumHeight: Kirigami.Units.gridUnit * 5

                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.alternateBackgroundColor
                border.color: Kirigami.Theme.separatorColor
                border.width: 1
                clip: true

                Image {
                    id: previewImage
                    anchors.fill: parent
                    source: card.resolvedImageSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true

                    PlasmaComponents.BusyIndicator {
                        anchors.centerIn: parent
                        running: previewImage.status === Image.Loading
                        visible: running
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        source: "image-missing"
                        visible: previewImage.status === Image.Error
                        implicitWidth: Kirigami.Units.iconSizes.large
                        implicitHeight: Kirigami.Units.iconSizes.large
                    }
                }
            }

            // Filename label with ToolTip for full path
            PlasmaComponents.Label {
                text: card.displayFileName
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                color: Kirigami.Theme.disabledTextColor
                Layouts.Layout.fillWidth: true
                elide: Text.ElideMiddle

                PlasmaComponents.ToolTip.text: card.isCustom ? card.pathText : card.displayFileName
                PlasmaComponents.ToolTip.visible: cardHoverArea.containsMouse
            }

            MouseArea {
                id: cardHoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                z: -1
            }

            // Integrated Action Buttons
            Layouts.RowLayout {
                Layouts.Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Button {
                    Layouts.Layout.fillWidth: true
                    icon.name: "document-open"
                    text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
                    onClicked: fileDialog.open()
                }

                PlasmaComponents.Button {
                    icon.name: "edit-undo"
                    text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default")
                    enabled: card.isCustom
                    visible: card.isCustom
                    onClicked: {
                        card.pathText = "";
                        root.configurationChanged();
                    }
                }
            }
        }

        QtDialogs.FileDialog {
            id: fileDialog
            title: card.dialogTitle
            nameFilters: [
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Image Files (*.png *.jpg *.jpeg *.webp *.avif *.svg)"),
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "All Files (*)")
            ]
            onAccepted: {
                let selected = fileDialog.selectedFile.toString();
                if (selected.startsWith("file://")) {
                    selected = selected.substring(7);
                }
                card.pathText = selected;
                root.configurationChanged();
            }
        }
    }

    Kirigami.FormLayout {
        id: innerFormLayout

        Layouts.Layout.fillWidth: true
        twinFormLayouts: root.parentLayout ? [root.parentLayout] : []

        // ==========================================
        // SECTION 1: Automatic Solar Detection & System Location
        // ==========================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Schedule Mode")
        }

        PlasmaComponents.CheckBox {
            id: autoScheduleCheckBox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Solar detection:")
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Calculate switch times automatically (Sunrise, Solar Noon, Sunset, Dusk)")
            checked: true
            onToggled: root.configurationChanged()
        }

        // Solar calculation preview message
        Kirigami.InlineMessage {
            id: solarInfoMessage
            visible: autoScheduleCheckBox.checked
            type: Kirigami.MessageType.Information
            Layouts.Layout.fillWidth: true
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight",
                "Today's calculated times:\n• Morning (Sunrise): %1\n• Noon (Solar Noon): %2\n• Evening (Sunset): %3\n• Night (Dusk): %4",
                TimeUtils.formatMinutes(root.currentSolarSchedule.morning),
                TimeUtils.formatMinutes(root.currentSolarSchedule.noon),
                TimeUtils.formatMinutes(root.currentSolarSchedule.evening),
                TimeUtils.formatMinutes(root.currentSolarSchedule.night)
            )
        }

        Layouts.RowLayout {
            visible: autoScheduleCheckBox.checked
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "System Settings:")
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                icon.name: "preferences-system-time"
                text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Open System Date, Time & Location Settings...")
                onClicked: {
                    Qt.openUrlExternally("kcm:kcm_clock");
                }
            }

            PlasmaComponents.Button {
                icon.name: "redshift-status-on"
                text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night Light Settings...")
                onClicked: {
                    Qt.openUrlExternally("kcm:kcm_nightlight");
                }
            }
        }

        // ==========================================
        // SECTION 2: Manual Schedules (if Auto disabled)
        // ==========================================
        Kirigami.Separator {
            visible: !autoScheduleCheckBox.checked
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Manual Time Periods")
        }

        TimeInputRow {
            id: morningTimeRow
            visible: !autoScheduleCheckBox.checked
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning starts at:")

            PlasmaComponents.SpinBox {
                id: morningHourSpin
                from: 0
                to: 23
                editable: true
                value: 6
                onValueModified: root.configurationChanged()
            }
            PlasmaComponents.Label {
                text: ":"
                font.bold: true
            }
            PlasmaComponents.SpinBox {
                id: morningMinuteSpin
                from: 0
                to: 59
                editable: true
                value: 0
                textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
                onValueModified: root.configurationChanged()
            }
        }

        TimeInputRow {
            id: noonTimeRow
            visible: !autoScheduleCheckBox.checked
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon starts at:")

            PlasmaComponents.SpinBox {
                id: noonHourSpin
                from: 0
                to: 23
                editable: true
                value: 12
                onValueModified: root.configurationChanged()
            }
            PlasmaComponents.Label {
                text: ":"
                font.bold: true
            }
            PlasmaComponents.SpinBox {
                id: noonMinuteSpin
                from: 0
                to: 59
                editable: true
                value: 0
                textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
                onValueModified: root.configurationChanged()
            }
        }

        TimeInputRow {
            id: eveningTimeRow
            visible: !autoScheduleCheckBox.checked
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening starts at:")

            PlasmaComponents.SpinBox {
                id: eveningHourSpin
                from: 0
                to: 23
                editable: true
                value: 18
                onValueModified: root.configurationChanged()
            }
            PlasmaComponents.Label {
                text: ":"
                font.bold: true
            }
            PlasmaComponents.SpinBox {
                id: eveningMinuteSpin
                from: 0
                to: 59
                editable: true
                value: 0
                textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
                onValueModified: root.configurationChanged()
            }
        }

        TimeInputRow {
            id: nightTimeRow
            visible: !autoScheduleCheckBox.checked
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night starts at:")

            PlasmaComponents.SpinBox {
                id: nightHourSpin
                from: 0
                to: 23
                editable: true
                value: 22
                onValueModified: root.configurationChanged()
            }
            PlasmaComponents.Label {
                text: ":"
                font.bold: true
            }
            PlasmaComponents.SpinBox {
                id: nightMinuteSpin
                from: 0
                to: 59
                editable: true
                value: 0
                textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
                onValueModified: root.configurationChanged()
            }
        }

        // ==========================================
        // SECTION 3: Visual Wallpaper Preview Cards (16:9)
        // ==========================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Images")
        }

        Layouts.GridLayout {
            id: wallpapersGrid
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Wallpapers:")
            Layouts.Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.largeSpacing
            rowSpacing: Kirigami.Units.largeSpacing

            WallpaperPreviewCard {
                id: morningCard
                periodTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning wallpaper:")
                periodIcon: "weather-sunset-up"
                defaultFileName: "matin.png"
                dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Morning Wallpaper")
            }

            WallpaperPreviewCard {
                id: noonCard
                periodTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon wallpaper:")
                periodIcon: "weather-clear"
                defaultFileName: "midi.png"
                dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Noon Wallpaper")
            }

            WallpaperPreviewCard {
                id: eveningCard
                periodTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening wallpaper:")
                periodIcon: "weather-sunset-down"
                defaultFileName: "soir.png"
                dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Evening Wallpaper")
            }

            WallpaperPreviewCard {
                id: nightCard
                periodTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night wallpaper:")
                periodIcon: "weather-clear-night"
                defaultFileName: "nuit.png"
                dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Night Wallpaper")
            }
        }

        // ==========================================
        // SECTION 4: Appearance & Transition
        // ==========================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Appearance")
        }

        PlasmaComponents.ComboBox {
            id: fillModeCombo
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Fill Mode:")
            model: [
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Scaled (Stretch)"),
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Zoom / Crop (Preserve Aspect Ratio)"),
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Fit (Preserve Aspect Ratio)")
            ]
            currentIndex: 1
            onActivated: root.configurationChanged()
        }

        Layouts.RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Transition duration:")
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.SpinBox {
                id: transitionSpin
                from: 0
                to: 10000
                stepSize: 250
                value: 1500
                editable: true
                onValueModified: root.configurationChanged()
            }

            PlasmaComponents.Label {
                text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "ms")
            }
        }

        // ==========================================
        // SECTION 5: Reset
        // ==========================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Reset")
        }

        Layouts.RowLayout {
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Defaults:")

            PlasmaComponents.Button {
                icon.name: "document-revert"
                text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Restore Default Configuration")
                onClicked: root.resetToDefaults()
            }
        }
    }
}
