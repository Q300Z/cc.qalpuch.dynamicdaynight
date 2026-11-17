/*
    SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QtControls2
import QtQuick.Layouts as Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
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

    // Liaisons déclaratives KConfigXT (et valeurs par défaut pour le bouton natif KCM)
    property alias cfg_AutoSchedule: autoScheduleCheckBox.checked
    property bool cfg_AutoScheduleDefault: true

    property alias cfg_MorningHour: morningHourSpin.value
    property int cfg_MorningHourDefault: 6
    property alias cfg_MorningMinute: morningMinuteSpin.value
    property int cfg_MorningMinuteDefault: 0

    property alias cfg_NoonHour: noonHourSpin.value
    property int cfg_NoonHourDefault: 12
    property alias cfg_NoonMinute: noonMinuteSpin.value
    property int cfg_NoonMinuteDefault: 0

    property alias cfg_EveningHour: eveningHourSpin.value
    property int cfg_EveningHourDefault: 18
    property alias cfg_EveningMinute: eveningMinuteSpin.value
    property int cfg_EveningMinuteDefault: 0

    property alias cfg_NightHour: nightHourSpin.value
    property int cfg_NightHourDefault: 22
    property alias cfg_NightMinute: nightMinuteSpin.value
    property int cfg_NightMinuteDefault: 0

    property alias cfg_MorningImage: morningRow.pathText
    property string cfg_MorningImageDefault: ""
    property alias cfg_NoonImage: noonRow.pathText
    property string cfg_NoonImageDefault: ""
    property alias cfg_EveningImage: eveningRow.pathText
    property string cfg_EveningImageDefault: ""
    property alias cfg_NightImage: nightRow.pathText
    property string cfg_NightImageDefault: ""

    property alias cfg_FillMode: fillModeCombo.currentIndex
    property int cfg_FillModeDefault: 1
    property color cfg_BackgroundColor: "#000000"
    property color cfg_BackgroundColorDefault: "#000000"
    property alias cfg_TransitionDuration: transitionSpin.value
    property int cfg_TransitionDurationDefault: 1500

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
        return TimeUtils.getPeriodDisplayName(period, i18nd);
    }

    // Calcul des éphémérides solaires du jour selon la localisation système
    readonly property var currentSolarSchedule: {
        const d = new Date();
        const sys = TimeUtils.getSystemCoordinates();
        return TimeUtils.calculateSolarSchedule(d, sys.lat, sys.lon);
    }

    // Propriétés de la boîte de dialogue d'aperçu agrandi
    property string previewDialogTitle: ""
    property url previewDialogSource

    function openLargePreview(title, sourceUrl) {
        previewDialogTitle = title;
        previewDialogSource = sourceUrl;
        imagePreviewPopup.open();
    }

    /**
     * Restaure l'ensemble des paramètres aux valeurs par défaut KConfigXT.
     */
    function resetToDefaults() {
        autoScheduleCheckBox.checked = root.cfg_AutoScheduleDefault;

        morningHourSpin.value = root.cfg_MorningHourDefault;
        morningMinuteSpin.value = root.cfg_MorningMinuteDefault;
        noonHourSpin.value = root.cfg_NoonHourDefault;
        noonMinuteSpin.value = root.cfg_NoonMinuteDefault;
        eveningHourSpin.value = root.cfg_EveningHourDefault;
        eveningMinuteSpin.value = root.cfg_EveningMinuteDefault;
        nightHourSpin.value = root.cfg_NightHourDefault;
        nightMinuteSpin.value = root.cfg_NightMinuteDefault;

        morningRow.pathText = root.cfg_MorningImageDefault;
        noonRow.pathText = root.cfg_NoonImageDefault;
        eveningRow.pathText = root.cfg_EveningImageDefault;
        nightRow.pathText = root.cfg_NightImageDefault;

        fillModeCombo.currentIndex = root.cfg_FillModeDefault;
        root.cfg_BackgroundColor = root.cfg_BackgroundColorDefault;
        transitionSpin.value = root.cfg_TransitionDurationDefault;

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

                QtControls2.ToolTip.text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Click to enlarge")
                QtControls2.ToolTip.visible: containsMouse
            }
        }

        // Champ de saisie du chemin de fichier
        QtControls2.TextField {
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
        QtControls2.Button {
            id: browseBtn
            icon.name: "document-open"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Browse...")
            onClicked: fileDialog.open()
        }

        // Bouton Restaurer par défaut
        QtControls2.Button {
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

    QtControls2.CheckBox {
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

        QtControls2.Button {
            icon.name: "preferences-system-time"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Open System Date, Time & Location Settings...")
            enabled: KConfig.KAuthorized.authorizeControlModule("kcm_clock")
            onClicked: {
                KCM.KCMLauncher.openSystemSettings("kcm_clock");
            }
        }

        QtControls2.Button {
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

        QtControls2.SpinBox {
            id: morningHourSpin
            from: 0
            to: 23
            editable: true
            value: 6
            onValueModified: root.configurationChanged()
        }
        QtControls2.Label {
            text: ":"
            font.bold: true
        }
        QtControls2.SpinBox {
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

        QtControls2.SpinBox {
            id: noonHourSpin
            from: 0
            to: 23
            editable: true
            value: 12
            onValueModified: root.configurationChanged()
        }
        QtControls2.Label {
            text: ":"
            font.bold: true
        }
        QtControls2.SpinBox {
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

        QtControls2.SpinBox {
            id: eveningHourSpin
            from: 0
            to: 23
            editable: true
            value: 18
            onValueModified: root.configurationChanged()
        }
        QtControls2.Label {
            text: ":"
            font.bold: true
        }
        QtControls2.SpinBox {
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

        QtControls2.SpinBox {
            id: nightHourSpin
            from: 0
            to: 23
            editable: true
            value: 22
            onValueModified: root.configurationChanged()
        }
        QtControls2.Label {
            text: ":"
            font.bold: true
        }
        QtControls2.SpinBox {
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

    QtControls2.ComboBox {
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
        visible: fillModeCombo.currentIndex === 2
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Background color:")
        spacing: Kirigami.Units.smallSpacing

        QtControls2.Button {
            id: bgColorBtn
            text: root.cfg_BackgroundColor.toString().toUpperCase()
            Accessible.name: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Background Color")
            onClicked: bgColorDialog.open()

            contentItem: Layouts.RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    implicitWidth: Kirigami.Units.gridUnit
                    implicitHeight: Kirigami.Units.gridUnit
                    radius: Kirigami.Units.smallSpacing / 2
                    color: root.cfg_BackgroundColor
                    border.color: Kirigami.Theme.disabledTextColor
                    border.width: 1
                }

                QtControls2.Label {
                    text: bgColorBtn.text
                }
            }
        }

        QtDialogs.ColorDialog {
            id: bgColorDialog
            title: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Select Background Color")
            selectedColor: root.cfg_BackgroundColor
            onAccepted: {
                root.cfg_BackgroundColor = selectedColor;
                root.configurationChanged();
            }
        }
    }

    Layouts.RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Transition duration:")
        spacing: Kirigami.Units.smallSpacing

        QtControls2.SpinBox {
            id: transitionSpin
            from: 0
            to: 10000
            stepSize: 250
            value: 1500
            editable: true
            onValueModified: root.configurationChanged()
        }

        QtControls2.Label {
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

        QtControls2.Button {
            icon.name: "document-revert"
            text: i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Restore Default Configuration")
            onClicked: root.resetToDefaults()
        }
    }

    // Fenêtre modale d'aperçu d'image en grand format
    Kirigami.Dialog {
        id: imagePreviewPopup
        title: root.previewDialogTitle
        modal: true
        standardButtons: Kirigami.Dialog.Close
        preferredWidth: Kirigami.Units.gridUnit * 38
        preferredHeight: Kirigami.Units.gridUnit * 24
        padding: Kirigami.Units.largeSpacing

        Rectangle {
            implicitWidth: Kirigami.Units.gridUnit * 36
            implicitHeight: Kirigami.Units.gridUnit * 21
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
