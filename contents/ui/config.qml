/*
    SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts as Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import "TimeUtils.js" as TimeUtils

Kirigami.FormLayout {
    id: root

    // Properties injected by KDE Plasma 6 kcm_wallpaper
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout

    twinFormLayouts: parentLayout

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

    // Image path bindings (direct link to single pathField in each FilePathRow)
    property alias cfg_MorningImage: morningImageRow.pathText
    property alias cfg_NoonImage: noonImageRow.pathText
    property alias cfg_EveningImage: eveningImageRow.pathText
    property alias cfg_NightImage: nightImageRow.pathText

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

        morningImageRow.pathText = "";
        noonImageRow.pathText = "";
        eveningImageRow.pathText = "";
        nightImageRow.pathText = "";

        fillModeCombo.currentIndex = 1;
        transitionSpin.value = 1500;
    }

    // Helper component for time slot spinboxes
    component TimeInputRow: Layouts.RowLayout {
        property alias hourValue: hourSpin.value
        property alias minuteValue: minSpin.value

        spacing: Kirigami.Units.smallSpacing

        QQC2.SpinBox {
            id: hourSpin
            from: 0
            to: 23
            editable: true
        }

        QQC2.Label {
            text: ":"
            font.bold: true
        }

        QQC2.SpinBox {
            id: minSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(value) {
                return (value < 10 ? "0" : "") + value;
            }
        }
    }

    // Helper component for file picker (single clean input row)
    component FilePathRow: Layouts.RowLayout {
        id: fileRow
        property alias pathText: pathField.text
        property string defaultImageName: ""
        property string dialogTitle: ""

        spacing: Kirigami.Units.smallSpacing
        Layouts.Layout.fillWidth: true

        QQC2.TextField {
            id: pathField
            Layouts.Layout.fillWidth: true
            placeholderText: fileRow.defaultImageName
        }

        QQC2.Button {
            icon.name: "document-open"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
            onClicked: fileDialog.open()
        }

        QQC2.Button {
            icon.name: "edit-undo"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default")
            enabled: pathField.text.length > 0
            onClicked: pathField.text = ""
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
                pathField.text = selected;
            }
        }
    }

    // ==========================================
    // SECTION 1: Automatic Solar Detection & System Location
    // ==========================================
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Schedule Mode")
    }

    QQC2.CheckBox {
        id: autoScheduleCheckBox
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Solar detection:")
        text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Calculate switch times automatically (Sunrise, Solar Noon, Sunset, Dusk)")
        checked: true
    }

    // Solar calculation preview card
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

        QQC2.Button {
            icon.name: "preferences-system-time"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Open System Date, Time & Location Settings...")
            onClicked: {
                Qt.openUrlExternally("kcm:kcm_clock");
            }
        }

        QQC2.Button {
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
        id: morningRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning starts at:")
        property alias hourSpin: morningHourSpin
        property alias minSpin: morningMinuteSpin

        QQC2.SpinBox { id: morningHourSpin; from: 0; to: 23; editable: true; value: 6 }
        QQC2.Label { text: ":" }
        QQC2.SpinBox {
            id: morningMinuteSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
        }
    }

    TimeInputRow {
        id: noonRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon starts at:")
        QQC2.SpinBox { id: noonHourSpin; from: 0; to: 23; editable: true; value: 12 }
        QQC2.Label { text: ":" }
        QQC2.SpinBox {
            id: noonMinuteSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
        }
    }

    TimeInputRow {
        id: eveningRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening starts at:")
        QQC2.SpinBox { id: eveningHourSpin; from: 0; to: 23; editable: true; value: 18 }
        QQC2.Label { text: ":" }
        QQC2.SpinBox {
            id: eveningMinuteSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
        }
    }

    TimeInputRow {
        id: nightRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night starts at:")
        QQC2.SpinBox { id: nightHourSpin; from: 0; to: 23; editable: true; value: 22 }
        QQC2.Label { text: ":" }
        QQC2.SpinBox {
            id: nightMinuteSpin
            from: 0
            to: 59
            editable: true
            value: 0
            textFromValue: function(v) { return (v < 10 ? "0" : "") + v; }
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
        id: morningImageRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning wallpaper:")
        defaultImageName: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "matin.png (Default)")
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Morning Wallpaper")
    }

    FilePathRow {
        id: noonImageRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon wallpaper:")
        defaultImageName: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "midi.png (Default)")
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Noon Wallpaper")
    }

    FilePathRow {
        id: eveningImageRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening wallpaper:")
        defaultImageName: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "soir.png (Default)")
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Evening Wallpaper")
    }

    FilePathRow {
        id: nightImageRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night wallpaper:")
        defaultImageName: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "nuit.png (Default)")
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Night Wallpaper")
    }

    // ==========================================
    // SECTION 4: Appearance & Transition
    // ==========================================
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Appearance")
    }

    QQC2.ComboBox {
        id: fillModeCombo
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Fill Mode:")
        model: [
            i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Scaled (Stretch)"),
            i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Zoom / Crop (Preserve Aspect Ratio)"),
            i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Fit (Preserve Aspect Ratio)")
        ]
        currentIndex: 1
    }

    Layouts.RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Transition duration:")
        spacing: Kirigami.Units.smallSpacing

        QQC2.SpinBox {
            id: transitionSpin
            from: 0
            to: 10000
            stepSize: 250
            value: 1500
            editable: true
        }

        QQC2.Label {
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

        QQC2.Button {
            icon.name: "document-revert"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Restore Default Configuration")
            onClicked: root.resetToDefaults()
        }
    }
}
