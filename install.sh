#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Script d'installation et désinstallation du fond d'écran dynamique Jour & Nuit pour KDE Plasma 6

set -euo pipefail

PLUGIN_ID="cc.qalpuch.dynamicdaynight"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_WALLPAPER_DIR="${HOME}/.local/share/plasma/wallpapers"
TARGET_LOCALE_DIR="${HOME}/.local/share/locale/fr/LC_MESSAGES"
TARGET_PLUGIN_PATH="${TARGET_WALLPAPER_DIR}/${PLUGIN_ID}"
TARGET_MO_FILE="${TARGET_LOCALE_DIR}/plasma_wallpaper_${PLUGIN_ID}.mo"

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --uninstall    Désinstalle le plugin et ses traductions"
    echo "  -h, --help         Affiche cette aide"
    echo ""
    echo "Sans argument, le script installe ou met à jour le plugin."
}

# Gestion des arguments
if [ "${1:-}" = "-u" ] || [ "${1:-}" = "--uninstall" ]; then
    echo "============================================================"
    echo " Désinstallation du fond d'écran dynamique Jour & Nuit"
    echo " Plugin ID : ${PLUGIN_ID}"
    echo "============================================================"

    if [ -L "${TARGET_PLUGIN_PATH}" ] || [ -d "${TARGET_PLUGIN_PATH}" ] || [ -e "${TARGET_PLUGIN_PATH}" ]; then
        echo "🗑️  Suppression du plugin : ${TARGET_PLUGIN_PATH}..."
        rm -rf "${TARGET_PLUGIN_PATH}"
    else
        echo "ℹ️  Plugin non trouvé dans ${TARGET_WALLPAPER_DIR}"
    fi

    if [ -f "${TARGET_MO_FILE}" ] || [ -L "${TARGET_MO_FILE}" ]; then
        echo "🗑️  Suppression du catalogue de traduction : ${TARGET_MO_FILE}..."
        rm -f "${TARGET_MO_FILE}"
    fi

    echo ""
    echo "============================================================"
    echo "🎉 Désinstallation terminée avec succès !"
    echo "============================================================"
    exit 0
elif [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    show_help
    exit 0
elif [ -n "${1:-}" ]; then
    echo "Option inconnue : $1"
    show_help
    exit 1
fi

echo "============================================================"
echo " Installation du fond d'écran dynamique Jour & Nuit"
echo " Plugin ID : ${PLUGIN_ID}"
echo "============================================================"

# 1. Compilation des catalogues de traduction
if command -v msgfmt &>/dev/null; then
    if [ -f "${SCRIPT_DIR}/po/fr.po" ]; then
        echo "⚙️  Compilation de la traduction française..."
        mkdir -p "${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES"
        msgfmt "${SCRIPT_DIR}/po/fr.po" -o "${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
    fi
else
    echo "⚠️  Avertissement : 'msgfmt' (gettext) n'est pas installé. Les traductions ne seront pas compilées."
fi

# 2. Création des répertoires cibles dans l'espace utilisateur
echo "📁 Création des dossiers cibles dans ~/.local/share/..."
mkdir -p "${TARGET_WALLPAPER_DIR}"
mkdir -p "${TARGET_LOCALE_DIR}"

# 3. Création du lien symbolique vers le paquet
echo "🔗 Liaison du plugin dans ${TARGET_PLUGIN_PATH}..."
ln -sfn "${SCRIPT_DIR}" "${TARGET_PLUGIN_PATH}"

# 4. Déploiement des traductions
MO_FILE="${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
if [ -f "${MO_FILE}" ]; then
    echo "🌍 Installation du catalogue de traduction..."
    cp "${MO_FILE}" "${TARGET_MO_FILE}"
fi

# 5. Validation du paquet avec kpackagetool6 si présent
if command -v kpackagetool6 &>/dev/null; then
    echo "✅ Validation du paquet KPackage..."
    kpackagetool6 --type Plasma/Wallpaper --show "${PLUGIN_ID}" >/dev/null && echo "   -> Paquet valide !"
fi

echo ""
echo "============================================================"
echo "🎉 Installation terminée avec succès !"
echo ""
echo "Pour l'activer :"
echo "1. Clic droit sur votre bureau -> 'Configurer le bureau et le fond d'écran...'"
echo "2. Choisir 'Fond d'écran dynamique Jour & Nuit' dans la liste."
echo ""
echo "Pour recharger Plasma Shell immédiatement (optionnel) :"
echo "   systemctl --user restart plasma-plasmashell"
echo "============================================================"
