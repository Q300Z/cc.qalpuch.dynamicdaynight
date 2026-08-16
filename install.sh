#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Script d'installation automatique du fond d'écran dynamique Jour & Nuit pour KDE Plasma 6

set -euo pipefail

PLUGIN_ID="cc.qalpuch.dynamicdaynight"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_WALLPAPER_DIR="${HOME}/.local/share/plasma/wallpapers"
TARGET_LOCALE_DIR="${HOME}/.local/share/locale/fr/LC_MESSAGES"

echo "============================================================"
echo " Installation du fond d'écran dynamique Jour & Nuit"
echo " Plugin ID : ${PLUGIN_ID}"
echo "============================================================"

# 1. Compilation des catalogues de traduction (si msgfmt est disponible)
if command -v msgfmt &>/dev/null && [ -f "${SCRIPT_DIR}/po/fr.po" ]; then
    echo "⚙️  Compilation de la traduction française..."
    mkdir -p "${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES"
    msgfmt "${SCRIPT_DIR}/po/fr.po" -o "${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
fi

# 2. Création des répertoires cibles dans l'espace utilisateur
echo "📁 Création des dossiers cibles dans ~/.local/share/..."
mkdir -p "${TARGET_WALLPAPER_DIR}"
mkdir -p "${TARGET_LOCALE_DIR}"

# 3. Création du lien symbolique vers le paquet
echo "🔗 Liaison du plugin dans ${TARGET_WALLPAPER_DIR}/${PLUGIN_ID}..."
ln -sfn "${SCRIPT_DIR}" "${TARGET_WALLPAPER_DIR}/${PLUGIN_ID}"

# 4. Déploiement des traductions
MO_FILE="${SCRIPT_DIR}/contents/locale/fr/LC_MESSAGES/plasma_wallpaper_${PLUGIN_ID}.mo"
if [ -f "${MO_FILE}" ]; then
    echo "🌍 Installation du catalogue de traduction..."
    cp "${MO_FILE}" "${TARGET_LOCALE_DIR}/"
fi

# 5. Validation du paquet avec kpackagetool6 si présent
if command -v kpackagetool6 &>/dev/null; then
    echo "✅ Validation du paquet KPackage..."
    kpackagetool6 --type Plasma/Wallpaper --show "${SCRIPT_DIR}" >/dev/null && echo "   -> Paquet valide !"
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
