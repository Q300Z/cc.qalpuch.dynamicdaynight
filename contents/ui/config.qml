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

    // Propriétés et signaux requis par le KCM de fond d'écran KDE Plasma 6
    property var configDialog
    property var wallpaperConfiguration
    property var parentLayout
    property alias formLayout: root
    twinFormLayouts: parentLayout ? [parentLayout] : []

    signal configurationChanged()

    // Liaisons déclaratives KConfigXT
    property alias cfg_AutoSchedule: autoScheduleCheckBox.checked

    property alias cfg_MorningHour: morningHourSpin.value
    property alias cfg_MorningMinute: morningMinuteSpin.value

    property alias cfg_NoonHour: noonHourSpin.value
    property alias cfg_NoonMinute: noonMinuteSpin.value

    property alias cfg_EveningHour: eveningHourSpin.value
    property alias cfg_EveningMinute: eveningMinuteSpin.value

    property alias cfg_NightHour: nightHourSpin.value
    property alias cfg_NightMinute: nightMinuteSpin.value

    property alias cfg_MorningImage: morningRow.pathText
    property alias cfg_NoonImage: noonRow.pathText
    property alias cfg_EveningImage: eveningRow.pathText
    property alias cfg_NightImage: nightRow.pathText

    property alias cfg_FillMode: fillModeCombo.currentIndex
    property alias cfg_TransitionDuration: transitionSpin.value

    // Horloge système et calcul en temps réel de la période active
    property var currentTime: new Date()

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
        }
    }

    readonly property string currentActivePeriod: {
        const cfg = {
            AutoSchedule: root.cfg_AutoSchedule,
            MorningHour: root.cfg_MorningHour,
            MorningMinute: root.cfg_MorningMinute,
            NoonHour: root.cfg_NoonHour,
            NoonMinute: root.cfg_NoonMinute,
            EveningHour: root.cfg_EveningHour,
            EveningMinute: root.cfg_EveningMinute,
            NightHour: root.cfg_NightHour,
            NightMinute: root.cfg_NightMinute
        };
        return TimeUtils.getCurrentPeriod(root.currentTime, cfg);
    }

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

    // Calcul des éphémérides solaires du jour selon la localisation système
    readonly property var currentSolarSchedule: {
        const d = new Date();
        const sys = TimeUtils.getSystemCoordinates();
        return TimeUtils.calculateSolarSchedule(d, sys.lat, sys.lon);
    }

    // Propriétés de la boîte de dialogue d'aperçu agrandi
    property string previewDialogTitle: ""
    property url previewDialogSource: ""

    function openLargePreview(title, sourceUrl) {
        previewDialogTitle = title;
        previewDialogSource = sourceUrl;
        imagePreviewPopup.open();
    }

    /**
     * Restaure l'ensemble des paramètres aux valeurs d'origine.
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

    // Composant réutilisable pour la sélection d'image avec miniature 16:9
    component
    FilePathRow: Layouts.RowLayout
    {
        id: fileRow

        property string defaultFileName: ""
        property string dialogTitle: ""
        property string pathText: ""
        property string periodKey: ""

        onPathTextChanged: {
            if (pathField.text !== pathText) {
                pathField.text = pathText;
            }
        }

        readonly property bool isCustom: pathText.trim().length > 0
        readonly property bool isActivePeriod: periodKey !== "" && periodKey === root.currentActivePeriod

        readonly property url resolvedImageSource: {
            if (fileRow.isCustom) {
                return TimeUtils.toSafeFileUrl(pathText);
            }
            return Qt.resolvedUrl("../images/" + defaultFileName);
        }

        spacing: Kirigami.Units.smallSpacing
        Layouts.Layout.fillWidth: true

        // Cadre de prévisualisation miniature 16:9 (accessible au clavier)
        Rectangle {
            id: thumbFrame
            Layouts.Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 3.2)
            Layouts.Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.8)
            radius: Kirigami.Units.smallSpacing / 2
            color: Kirigami.Theme.alternateBackgroundColor
            border.color: fileRow.isActivePeriod
                ? Kirigami.Theme.highlightColor
                : ((thumbMouseArea.containsMouse || thumbFrame.activeFocus) ? Kirigami.Theme.highlightColor : (fileRow.isCustom ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor))
            border.width: fileRow.isActivePeriod ? 2 : ((thumbMouseArea.containsMouse || thumbFrame.activeFocus || fileRow.isCustom) ? 1.5 : 1)
            clip: true

            focus: true
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: fileRow.dialogTitle
            Accessible.description: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Click to enlarge")
            Accessible.onPressAction: root.openLargePreview(fileRow.dialogTitle, fileRow.resolvedImageSource)

            Keys.onReturnPressed: root.openLargePreview(fileRow.dialogTitle, fileRow.resolvedImageSource)
            Keys.onSpacePressed: root.openLargePreview(fileRow.dialogTitle, fileRow.resolvedImageSource)

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

            // Icône de zoom au survol ou focus clavier
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.4)
                visible: thumbMouseArea.containsMouse || thumbFrame.activeFocus

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

        // Champ de saisie du chemin de fichier
        PlasmaComponents.TextField {
            id: pathField
            Layouts.Layout.fillWidth: true
            text: fileRow.pathText
            placeholderText: fileRow.defaultFileName + " (" + i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Default") + ")"
            onTextEdited: {
                fileRow.pathText = text;
                root.configurationChanged();
            }
            onEditingFinished: {
                fileRow.pathText = text;
            }
        }

        // Bouton Parcourir
        PlasmaComponents.Button {
            id: browseBtn
            icon.name: "document-open"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
            onClicked: fileDialog.open()
        }

        // Bouton Restaurer par défaut
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
                let selected = decodeURIComponent(fileDialog.selectedFile.toString());
                if (selected.startsWith("file://")) {
                    selected = selected.substring(7);
                }
                fileRow.pathText = selected;
                pathField.text = selected;
                root.configurationChanged();
            }
        }
    }

    // ==========================================
    // SECTION 1 : Détection solaire automatique & Localisation
    // ==========================================
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Schedule Mode")
    }

    // Bannière d'état de la période en cours
    Kirigami.InlineMessage {
        id: activePeriodBanner
        type: Kirigami.MessageType.Positive
        showCloseButton: false
        visible: true
        Layouts.Layout.fillWidth: true
        text: i18nd(
            "plasma_wallpaper_cc.qalpuch.dynamicdaynight",
            "Current period: %1 (%2)",
            root.getPeriodDisplayName(root.currentActivePeriod),
            Qt.formatTime(root.currentTime, "hh:mm")
        )
    }

    PlasmaComponents.CheckBox {
        id: autoScheduleCheckBox
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Solar detection:")
        text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Calculate switch times automatically (Sunrise, Solar Noon, Sunset, Dusk)")
        checked: true
        onToggled: root.configurationChanged()
    }

    // Message d'information sur les horaires solaires calculés
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
    // SECTION 2 : Plages horaires manuelles (si mode auto désactivé)
    // ==========================================
    Kirigami.Separator {
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Manual Time Periods")
    }

    Layouts.RowLayout {
        id: morningTimeRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning starts at:")
        spacing: Kirigami.Units.smallSpacing

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
            textFromValue: function (v) {
                return (v < 10 ? "0" : "") + v;
            }
            valueFromText: function (text) {
                return parseInt(text, 10) || 0;
            }
            onValueModified: root.configurationChanged()
        }
    }

    Layouts.RowLayout {
        id: noonTimeRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon starts at:")
        spacing: Kirigami.Units.smallSpacing

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
            textFromValue: function (v) {
                return (v < 10 ? "0" : "") + v;
            }
            valueFromText: function (text) {
                return parseInt(text, 10) || 0;
            }
            onValueModified: root.configurationChanged()
        }
    }

    Layouts.RowLayout {
        id: eveningTimeRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening starts at:")
        spacing: Kirigami.Units.smallSpacing

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
            textFromValue: function (v) {
                return (v < 10 ? "0" : "") + v;
            }
            valueFromText: function (text) {
                return parseInt(text, 10) || 0;
            }
            onValueModified: root.configurationChanged()
        }
    }

    Layouts.RowLayout {
        id: nightTimeRow
        visible: !autoScheduleCheckBox.checked
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night starts at:")
        spacing: Kirigami.Units.smallSpacing

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
            textFromValue: function (v) {
                return (v < 10 ? "0" : "") + v;
            }
            valueFromText: function (text) {
                return parseInt(text, 10) || 0;
            }
            onValueModified: root.configurationChanged()
        }
    }

    // ==========================================
    // SECTION 3 : Images (Matin, Midi, Soir, Nuit)
    // ==========================================
    Kirigami.Separator {
        Kirigami.FormData.isSection: true
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Images")
    }

    FilePathRow {
        id: morningRow
        periodKey: "morning"
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning wallpaper:")
        defaultFileName: "matin.png"
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Morning Wallpaper")
    }

    FilePathRow {
        id: noonRow
        periodKey: "noon"
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Noon wallpaper:")
        defaultFileName: "midi.png"
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Noon Wallpaper")
    }

    FilePathRow {
        id: eveningRow
        periodKey: "evening"
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Evening wallpaper:")
        defaultFileName: "soir.png"
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Evening Wallpaper")
    }

    FilePathRow {
        id: nightRow
        periodKey: "night"
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Night wallpaper:")
        defaultFileName: "nuit.png"
        dialogTitle: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Night Wallpaper")
    }

    // ==========================================
    // SECTION 4 : Apparence & Transitions
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
    // SECTION 5 : Réinitialisation
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

    // Fenêtre modale d'aperçu d'image en grand format
    PlasmaComponents.Popup {
        id: imagePreviewPopup
        anchors.centerIn: parent
        modal: true
        focus: true
        closePolicy: PlasmaComponents.Popup.CloseOnEscape | PlasmaComponents.Popup.CloseOnPressOutside
        width: Math.min(root.width * 0.9, Kirigami.Units.gridUnit * 42)
        height: Math.min(root.height * 0.9, Kirigami.Units.gridUnit * 26)
        padding: Kirigami.Units.largeSpacing

        contentItem: Layouts.ColumnLayout
        {
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
