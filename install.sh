#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Script d'installation et désinstallation du fond d'écran dynamique Jour & Nuit pour KDE Plasma 6

set -euo pipefail

PLUGIN_ID="cc.qalpuch.dynamicdaynight"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_WALLPAPER_DIR="${HOME}/.local/share/plasma/wallpapers"
LOCAL_SHARE_LOCALE="${HOME}/.local/share/locale"
TARGET_PLUGIN_PATH="${TARGET_WALLPAPER_DIR}/${PLUGIN_ID}"

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

    # Suppression dynamique des catalogues de traduction
    for po_file in "${SCRIPT_DIR}"/po/*.po; do
        [ -f "$po_file" ] || continue
        lang="$(basename "$po_file" .po)"
        target_mo="${LOCAL_SHARE_LOCALE}/${lang}/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
        if [ -f "${target_mo}" ] || [ -L "${target_mo}" ]; then
            echo "🗑️  Suppression du catalogue de traduction (${lang}) : ${target_mo}..."
            rm -f "${target_mo}"
        fi
    done

    # Suppression de catalogues résiduels éventuels
    for mo_file in "${LOCAL_SHARE_LOCALE}"/*/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo; do
        if [ -f "$mo_file" ] || [ -L "$mo_file" ]; then
            echo "🗑️  Suppression du catalogue résiduel : ${mo_file}..."
            rm -f "$mo_file"
        fi
    done

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
    for po_file in "${SCRIPT_DIR}"/po/*.po; do
        [ -f "$po_file" ] || continue
        lang="$(basename "$po_file" .po)"
        echo "⚙️  Compilation de la traduction (${lang})..."
        mkdir -p "${SCRIPT_DIR}/contents/locale/${lang}/LC_MESSAGES"
        msgfmt "$po_file" -o "${SCRIPT_DIR}/contents/locale/${lang}/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
    done
else
    echo "⚠️  Avertissement : 'msgfmt' (gettext) n'est pas installé. Les traductions ne seront pas compilées."
fi

# 2. Création des répertoires cibles dans l'espace utilisateur
echo "📁 Création des dossiers cibles dans ~/.local/share/..."
mkdir -p "${TARGET_WALLPAPER_DIR}"

# 3. Création du lien symbolique vers le paquet
echo "🔗 Liaison du plugin dans ${TARGET_PLUGIN_PATH}..."
rm -rf "${TARGET_PLUGIN_PATH}"
ln -sfn "${SCRIPT_DIR}" "${TARGET_PLUGIN_PATH}"

# 4. Déploiement dynamique des traductions
for po_file in "${SCRIPT_DIR}"/po/*.po; do
    [ -f "$po_file" ] || continue
    lang="$(basename "$po_file" .po)"
    src_mo="${SCRIPT_DIR}/contents/locale/${lang}/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
    dest_dir="${LOCAL_SHARE_LOCALE}/${lang}/LC_MESSAGES"
    dest_mo="${dest_dir}/plasma_wallpaper_${PLUGIN_ID}.mo"
    if [ -f "${src_mo}" ]; then
        echo "🌍 Installation du catalogue de traduction (${lang})..."
        mkdir -p "${dest_dir}"
        cp "${src_mo}" "${dest_mo}"
    fi
done

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
