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

Kirigami.FormLayout {
    id: root

    // Properties and signals expected by KDE Plasma 6 kcm_wallpaper
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout
    property alias formLayout: root
    twinFormLayouts: parentLayout ? [parentLayout] : []

    signal configurationChanged()

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

    // Custom accent color bindings
    property bool cfg_DynamicAccentColor: false
    property color cfg_MorningColor: "#1e3539"
    property color cfg_NoonColor: "#446c84"
    property color cfg_EveningColor: "#322f21"
    property color cfg_NightColor: "#48220b"

    // Behavior & Display settings
    property alias cfg_TransitionDuration: transitionSpin.value
    property alias cfg_FillMode: fillModeCombo.currentIndex

    // Real-time solar preview calculation for today based on system timezone/location
    readonly property var currentSolarSchedule: {
        const d = new Date();
        const sys = TimeUtils.getSystemCoordinates();
        return TimeUtils.calculateSolarSchedule(d, sys.lat, sys.lon);
    }

    // Large Image Preview Dialog properties
    property string previewDialogTitle: ""
    property url previewDialogSource: ""

    function openLargePreview(title, sourceUrl) {
        previewDialogTitle = title;
        previewDialogSource = sourceUrl;
        imagePreviewPopup.open();
    }

    onWallpaperConfigurationChanged: {
        if (configDialog && configDialog.currentWallpaper && configDialog.currentWallpaper !== "cc.qalpuch.dynamicdaynight") {
            return;
        }
        if (wallpaperConfiguration) {
            if (wallpaperConfiguration["DynamicAccentColor"] !== undefined) {
                root.cfg_DynamicAccentColor = Boolean(wallpaperConfiguration["DynamicAccentColor"]);
            }
            if (wallpaperConfiguration["MorningColor"]) {
                root.cfg_MorningColor = wallpaperConfiguration["MorningColor"];
            }
            if (wallpaperConfiguration["NoonColor"]) {
                root.cfg_NoonColor = wallpaperConfiguration["NoonColor"];
            }
            if (wallpaperConfiguration["EveningColor"]) {
                root.cfg_EveningColor = wallpaperConfiguration["EveningColor"];
            }
            if (wallpaperConfiguration["NightColor"]) {
                root.cfg_NightColor = wallpaperConfiguration["NightColor"];
            }
        }
    }

    /**
     * Called by KDE Plasma kcm_wallpaper before committing configuration changes to disk.
     */
    function saveConfig() {
        if (configDialog && configDialog.currentWallpaper && configDialog.currentWallpaper !== "cc.qalpuch.dynamicdaynight") {
            return;
        }
        if (wallpaperConfiguration) {
            wallpaperConfiguration["AutoSchedule"] = root.cfg_AutoSchedule;
            wallpaperConfiguration["MorningHour"] = root.cfg_MorningHour;
            wallpaperConfiguration["MorningMinute"] = root.cfg_MorningMinute;
            wallpaperConfiguration["NoonHour"] = root.cfg_NoonHour;
            wallpaperConfiguration["NoonMinute"] = root.cfg_NoonMinute;
            wallpaperConfiguration["EveningHour"] = root.cfg_EveningHour;
            wallpaperConfiguration["EveningMinute"] = root.cfg_EveningMinute;
            wallpaperConfiguration["NightHour"] = root.cfg_NightHour;
            wallpaperConfiguration["NightMinute"] = root.cfg_NightMinute;
            wallpaperConfiguration["MorningImage"] = root.cfg_MorningImage;
            wallpaperConfiguration["NoonImage"] = root.cfg_NoonImage;
            wallpaperConfiguration["EveningImage"] = root.cfg_EveningImage;
            wallpaperConfiguration["NightImage"] = root.cfg_NightImage;
            wallpaperConfiguration["DynamicAccentColor"] = root.cfg_DynamicAccentColor;
            wallpaperConfiguration["MorningColor"] = String(root.cfg_MorningColor);
            wallpaperConfiguration["NoonColor"] = String(root.cfg_NoonColor);
            wallpaperConfiguration["EveningColor"] = String(root.cfg_EveningColor);
            wallpaperConfiguration["NightColor"] = String(root.cfg_NightColor);
            wallpaperConfiguration["FillMode"] = root.cfg_FillMode;
            wallpaperConfiguration["TransitionDuration"] = root.cfg_TransitionDuration;
        }
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

        root.cfg_DynamicAccentColor = false;
        root.cfg_MorningColor = morningRow.defaultColor;
        root.cfg_NoonColor = noonRow.defaultColor;
        root.cfg_EveningColor = eveningRow.defaultColor;
        root.cfg_NightColor = nightRow.defaultColor;

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

    // Helper component for single-line file selection with compact inline 16:9 preview & color picker
    component FilePathRow: Layouts.RowLayout {
        id: fileRow

        property string defaultFileName: ""
        property color defaultColor: "#1E3539"
        property color selectedColor: defaultColor
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
                id: previewImage
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

        // Hidden Canvas for dominant color calculation
        Canvas {
            id: colorExtractorCanvas
            width: 32
            height: 32
            visible: false
            renderTarget: Canvas.Image

            property string activeLoadingUrl: ""

            function extractFromUrl(urlToLoad) {
                if (!urlToLoad) return;
                const strUrl = urlToLoad.toString();
                activeLoadingUrl = strUrl;
                loadImage(strUrl);
            }

            onImageLoaded: {
                requestPaint();
            }

            onPaint: {
                if (!activeLoadingUrl || !isImageLoaded(activeLoadingUrl)) return;
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.drawImage(activeLoadingUrl, 0, 0, width, height);
                const extracted = TimeUtils.extractDominantColor(ctx, width, height, fileRow.defaultColor);
                if (extracted && String(fileRow.selectedColor).toLowerCase() !== String(extracted).toLowerCase()) {
                    fileRow.selectedColor = extracted;
                }
                unloadImage(activeLoadingUrl);
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
                if (text.trim().length > 0) {
                    colorExtractorCanvas.extractFromUrl(fileRow.resolvedImageSource);
                }
                root.configurationChanged();
            }
        }

        // Browse button
        PlasmaComponents.Button {
            id: browseBtn
            icon.name: "document-open"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
            onClicked: fileDialog.open()
        }

        // Dominant accent color customization button (visible only if dynamic accent color is enabled)
        PlasmaComponents.Button {
            id: colorButton
            visible: root.cfg_DynamicAccentColor
            implicitWidth: Kirigami.Units.gridUnit * 2.4
            implicitHeight: browseBtn.implicitHeight

            PlasmaComponents.ToolTip.text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Accent color: %1 (click to customize)", String(fileRow.selectedColor))
            PlasmaComponents.ToolTip.visible: hovered

            Rectangle {
                anchors.centerIn: parent
                width: Kirigami.Units.gridUnit * 1.3
                height: Kirigami.Units.gridUnit * 1.1
                radius: Kirigami.Units.smallSpacing / 2
                color: fileRow.selectedColor
                border.color: Kirigami.Theme.disabledTextColor
                border.width: 1
            }

            onClicked: colorDialog.open()
        }

        Component.onCompleted: {
            if (!fileRow.selectedColor || fileRow.selectedColor === "" || String(fileRow.selectedColor) === "#00000000") {
                colorExtractorCanvas.extractFromUrl(fileRow.resolvedImageSource);
            }
        }

        // Reset to default button
        PlasmaComponents.Button {
            icon.name: "edit-undo"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default")
            enabled: fileRow.isCustom || (String(fileRow.selectedColor).toLowerCase() !== String(fileRow.defaultColor).toLowerCase())
            onClicked: {
                fileRow.pathText = "";
                pathField.text = "";
                fileRow.selectedColor = fileRow.defaultColor;
                colorExtractorCanvas.extractFromUrl(fileRow.resolvedImageSource);
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
                colorExtractorCanvas.extractFromUrl(fileRow.resolvedImageSource);
                root.configurationChanged();
            }
        }

        QtDialogs.ColorDialog {
            id: colorDialog
            title: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Accent Color")
            selectedColor: fileRow.selectedColor
            onAccepted: {
                fileRow.selectedColor = selectedColor;
                root.configurationChanged();
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
        defaultColor: "#1e3539"
        selectedColor: root.cfg_MorningColor
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Morning Wallpaper")
        onSelectedColorChanged: {
            if (String(root.cfg_MorningColor).toLowerCase() !== String(selectedColor).toLowerCase()) {
                root.cfg_MorningColor = selectedColor;
                root.configurationChanged();
            }
        }
    }

    FilePathRow {
        id: noonRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon wallpaper:")
        defaultFileName: "midi.png"
        defaultColor: "#446c84"
        selectedColor: root.cfg_NoonColor
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Noon Wallpaper")
        onSelectedColorChanged: {
            if (String(root.cfg_NoonColor).toLowerCase() !== String(selectedColor).toLowerCase()) {
                root.cfg_NoonColor = selectedColor;
                root.configurationChanged();
            }
        }
    }

    FilePathRow {
        id: eveningRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening wallpaper:")
        defaultFileName: "soir.png"
        defaultColor: "#322f21"
        selectedColor: root.cfg_EveningColor
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Evening Wallpaper")
        onSelectedColorChanged: {
            if (String(root.cfg_EveningColor).toLowerCase() !== String(selectedColor).toLowerCase()) {
                root.cfg_EveningColor = selectedColor;
                root.configurationChanged();
            }
        }
    }

    FilePathRow {
        id: nightRow
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night wallpaper:")
        defaultFileName: "nuit.png"
        defaultColor: "#48220b"
        selectedColor: root.cfg_NightColor
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Night Wallpaper")
        onSelectedColorChanged: {
            if (String(root.cfg_NightColor).toLowerCase() !== String(selectedColor).toLowerCase()) {
                root.cfg_NightColor = selectedColor;
                root.configurationChanged();
            }
        }
    }

    // ==========================================
    // SECTION 4: Appearance & Transition
    // ==========================================
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Appearance")
    }

    PlasmaComponents.CheckBox {
        id: dynamicAccentColorCheckBox
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Accent color:")
        text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Synchronize KDE Plasma accent color with active wallpaper period")
        checked: root.cfg_DynamicAccentColor
        onToggled: {
            root.cfg_DynamicAccentColor = checked;
            root.configurationChanged();
        }
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
