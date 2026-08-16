/*
    SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts as Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
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
    property alias cfg_MorningImage: morningRow.pathText
    property alias cfg_NoonImage: noonRow.pathText
    property alias cfg_EveningImage: eveningRow.pathText
    property alias cfg_NightImage: nightRow.pathText

    // Behavior & Display settings
    property alias cfg_TransitionDuration: transitionSpin.value
    property alias cfg_FillMode: fillModeCombo.currentIndex

    // Real-time solar preview calculation for today based on system timezone/location
    readonly property var currentSolarSchedule: {
        const d = new Date();
        const sys = TimeUtils.getSystemCoordinates();
        return TimeUtils.calculateSolarSchedule(d, sys.lat, sys.lon);
    }

    // Large Image Preview Dialog
    property string previewDialogTitle: ""
    property url previewDialogSource: ""

    function openLargePreview(title, sourceUrl) {
        previewDialogTitle = title;
        previewDialogSource = sourceUrl;
        imagePreviewPopup.open();
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

        morningRow.pathText = "";
        noonRow.pathText = "";
        eveningRow.pathText = "";
        nightRow.pathText = "";

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

    // Helper component for single-line file selection with compact inline 16:9 preview
    component FilePathRow: Layouts.RowLayout {
        id: fileRow

        property string defaultFileName: ""
        property string dialogTitle: ""
        property string pathText: ""

        readonly property bool isCustom: pathText.trim().length > 0

        readonly property url resolvedImageSource: {
            if (fileRow.isCustom) {
                const trimmed = pathText.trim();
                return trimmed.startsWith("file://") ? trimmed : "file://" + trimmed;
            }
            return Qt.resolvedUrl("../images/" + defaultFileName);
        }

        spacing: Kirigami.Units.smallSpacing
        Layouts.Layout.fillWidth: true

        // Compact 16:9 Thumbnail preview (clickable to open large preview)
        Rectangle {
            id: thumbFrame
            Layouts.Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 3.2)
            Layouts.Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.8)
            radius: Kirigami.Units.smallSpacing / 2
            color: Kirigami.Theme.alternateBackgroundColor
            border.color: thumbMouseArea.containsMouse ? Kirigami.Theme.highlightColor : (fileRow.isCustom ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor)
            border.width: (thumbMouseArea.containsMouse || fileRow.isCustom) ? 1.5 : 1
            clip: true

            Image {
                anchors.fill: parent
                source: fileRow.resolvedImageSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
            }

            // Zoom icon overlay on hover
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
                visible: thumbMouseArea.containsMouse

                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "zoom-in"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
            }

            MouseArea {
                id: thumbMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openLargePreview(fileRow.dialogTitle, fileRow.resolvedImageSource)

                PlasmaComponents.ToolTip.text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Click to enlarge")
                PlasmaComponents.ToolTip.visible: containsMouse
            }
        }

        // Path field
        PlasmaComponents.TextField {
            id: pathField
            Layouts.Layout.fillWidth: true
            text: fileRow.pathText
            placeholderText: fileRow.defaultFileName + " (" + i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default") + ")"
            onTextEdited: {
                fileRow.pathText = text;
                root.configurationChanged();
            }
        }

        // Browse button
        PlasmaComponents.Button {
            icon.name: "document-open"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
            onClicked: fileDialog.open()
        }

        // Reset to default button
        PlasmaComponents.Button {
            icon.name: "edit-undo"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default")
            enabled: fileRow.isCustom
            onClicked: {
                fileRow.pathText = "";
                pathField.text = "";
                root.configurationChanged();
            }
        }

        QtDialogs.FileDialog {
            id: fileDialog
            title: fileRow.dialogTitle
            nameFilters: [
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Image Files (*.png *.jpg *.jpeg *.webp *.avif *.svg)"),
                i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "All Files (*)")
            ]
            onAccepted: {
                let selected = fileDialog.selectedFile.toString();
                if (selected.startsWith("file://")) {
                    selected = selected.substring(7);
                }
                fileRow.pathText = selected;
                pathField.text = selected;
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
                enabled: KConfig.KAuthorized.authorizeControlModule("kcm_clock")
                onClicked: {
                    KCM.KCMLauncher.openSystemSettings("kcm_clock");
                }
            }

            PlasmaComponents.Button {
                icon.name: "redshift-status-on"
                text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night Light Settings...")
                enabled: KConfig.KAuthorized.authorizeControlModule("kcm_nightlight")
                onClicked: {
                    KCM.KCMLauncher.openSystemSettings("kcm_nightlight");
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
        // SECTION 3: Images (Matin, Midi, Soir, Nuit)
        // ==========================================
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Images")
        }

        FilePathRow {
            id: morningRow
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning wallpaper:")
            defaultFileName: "matin.png"
            dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Morning Wallpaper")
        }

        FilePathRow {
            id: noonRow
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon wallpaper:")
            defaultFileName: "midi.png"
            dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Noon Wallpaper")
        }

        FilePathRow {
            id: eveningRow
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening wallpaper:")
            defaultFileName: "soir.png"
            dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Evening Wallpaper")
        }

        FilePathRow {
            id: nightRow
            Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night wallpaper:")
            defaultFileName: "nuit.png"
            dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Night Wallpaper")
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

    // Modal popup to display the wallpaper image in full / large view
    PlasmaComponents.Popup {
        id: imagePreviewPopup
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: PlasmaComponents.Popup.CloseOnEscape | PlasmaComponents.Popup.CloseOnPressOutside
        width: Math.min(root.width * 0.9, Kirigami.Units.gridUnit * 42)
        height: Math.min(root.height * 0.9, Kirigami.Units.gridUnit * 26)
        padding: Kirigami.Units.largeSpacing

        contentItem: Layouts.ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Layouts.RowLayout {
                Layouts.Layout.fillWidth: true

                PlasmaComponents.Label {
                    text: root.previewDialogTitle
                    font.weight: Font.Bold
                    Layouts.Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                PlasmaComponents.Button {
                    icon.name: "window-close"
                    text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Close")
                    onClicked: imagePreviewPopup.close()
                }
            }

            Rectangle {
                Layouts.Layout.fillWidth: true
                Layouts.Layout.fillHeight: true
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    source: root.previewDialogSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    smooth: true
                    mipmap: true
                }
            }
        }
    }
}
