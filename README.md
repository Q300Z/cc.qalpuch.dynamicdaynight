# Fond d'écran dynamique Jour & Nuit (KDE Plasma 6)

Plugin de fond d'écran dynamique pour **KDE Plasma 6** (`cc.qalpuch.dynamicdaynight`) qui adapte automatiquement votre
fond d'écran selon le cycle de la journée (**Matin**, **Midi**, **Soir**, **Nuit**), avec transition fluide en fondu
enchaîné (*crossfade*), calculs astronomiques de la position solaire et personnalisation complète.

---

## Sommaire

- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Installation](#installation)
    - [1. Installation automatique (Recommandé)](#1-installation-automatique-recommandé)
    - [2. Installation manuelle](#2-installation-manuelle)
- [Utilisation](#utilisation)
- [Développement & Architecture](#développement--architecture)
    - [Structure du projet](#structure-du-projet)
    - [Internationalisation (i18n)](#internationalisation-i18n)
    - [Commandes utiles](#commandes-utiles)
- [Contribution & Communauté](#contribution--communauté)
- [Licence](#licence)

---

## Présentation

Ce plugin est conçu nativement pour **KDE Plasma 6** (Qt 6 / KF6) selon les standards et conventions de la communauté
KDE :

- **Clé en main (*Out-of-the-box*) :** Embarque 4 illustrations haute qualité pour chaque moment de la journée dans
  `contents/images/`.
- **Calculs solaires automatiques :** Calcule les heures réelles du lever, du zénith, du coucher de soleil et du
  crépuscule en fonction du fuseau horaire de votre système (algorithme éphémérides solaires NOAA 100% hors-ligne).
- **Transitions douces :** Animation de fondu réglable (*crossfade*) pour éviter tout changement brusque.
- **Respect des principes KISS & DRY :** Code modulaire, séparation stricte des responsabilités (logique métier dans
  `TimeUtils.js`, schéma KConfigXT dans `main.xml`, interface déclarative dans `config.qml`).

---

## Fonctionnalités

- ☀️ **Détection solaire automatique :** Synchronisation sur le cycle réel du soleil sans connexion Internet requise
  (éphémérides NOAA hors-ligne).
- 🕒 **Mode horaire manuel :** Possibilité de définir des plages horaires fixes personnalisées.
- 🖼️ **Images personnalisables :** Remplacement possible de chaque image (Matin, Midi, Soir, Nuit) avec miniatures 16:9
  et bouton de réinitialisation.
- 🎨 **Couleur d'accentuation dynamique native :** Compatible à 100% avec l'extraction automatique de couleur de KDE
  Plasma 6 (*Paramètres $\rightarrow$ Couleurs $\rightarrow$ Générer depuis le fond d'écran*).
- 📐 **Modes de remplissage :** Étiré, Recadré / Zoom (conserve les proportions), Ajusté.
- ⏱️ **Durée de transition ajustable :** Réglage précis de la durée du fondu enchaîné (*crossfade* en ms).
- 🌍 **Internationalisation (i18n) :** Support multilingue complet (Français et Anglais inclus).
- 🔄 **Bouton de réinitialisation :** Restauration des réglages d'origine en un seul clic.

---

## Installation

### 1. Installation automatique (Recommandé)

Cloner le dépôt, se placer à la racine du dossier cloné et exécuter le script d'installation :

```bash
# 1. Cloner le dépôt et se placer dans le dossier
git clone git@github.com:Q300Z/cc.qalpuch.dynamicdaynight.git
cd cc.qalpuch.dynamicdaynight

# 2. Lancer le script d'installation
chmod +x install.sh
./install.sh
```

---

### 2. Installation manuelle

Si vous préférez installer le plugin manuellement étape par étape depuis la racine du dossier cloné :

```bash
# 1. Cloner le dépôt et se placer dans le dossier
git clone git@github.com:Q300Z/cc.qalpuch.dynamicdaynight.git
cd cc.qalpuch.dynamicdaynight

# 2. Créer les répertoires cibles dans l'espace utilisateur
mkdir -p ~/.local/share/plasma/wallpapers
mkdir -p ~/.local/share/locale/fr/LC_MESSAGES

# 3. Créer le lien symbolique depuis la racine du dossier cloné
ln -sfn "$(pwd)" ~/.local/share/plasma/wallpapers/cc.qalpuch.dynamicdaynight

# 4. Compiler et installer le catalogue de traduction française
msgfmt po/fr.po -o contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo
cp contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo ~/.local/share/locale/fr/LC_MESSAGES/
```

*Alternative via `kpackagetool6` (depuis la racine du dossier) :*

```bash
kpackagetool6 --type Plasma/Wallpaper --install .
```

---

## Utilisation

1. Faites un **clic droit sur votre bureau** Plasma.
2. Cliquez sur **Configurer le bureau et le fond d'écran...**
3. Dans le menu déroulant **Type de fond d'écran**, sélectionnez :  
   `Fond d'écran dynamique Jour & Nuit`
4. Ajustez vos préférences dans la fenêtre de réglages :
    - **Mode de planification :** Cochez *Détection solaire* ou définissez vos heures manuellement.
    - **Images :** Conservez les images d'origine ou sélectionnez vos propres fichiers.
    - **Apparence :** Réglez le mode de redimensionnement et la durée du fondu.
5. Cliquez sur **Appliquer** ou **OK**.

---

## Développement & Architecture

### Structure du projet

```text
wallpaper/
├── LICENSE                       # Texte intégral de la licence GNU GPL v3
├── metadata.json                 # Métadonnées du KPackage Plasma 6 (Id: cc.qalpuch.dynamicdaynight)
├── install.sh                    # Script d'installation automatique
├── README.md                     # Documentation du projet
├── contents/
│   ├── config/
│   │   └── main.xml              # Schéma KConfigXT des paramètres utilisateur
│   ├── images/
│   │   ├── matin.png             # Image du matin (par défaut 06:00 -> 11:59)
│   │   ├── midi.png              # Image du midi (par défaut 12:00 -> 17:59)
│   │   ├── soir.png              # Image du soir (par défaut 18:00 -> 21:59)
│   │   └── nuit.png              # Image de nuit (par défaut 22:00 -> 05:59)
│   └── ui/
│       ├── TimeUtils.js          # Module métier (éphémérides solaires et résolutions)
│       ├── main.qml              # Vue principale (WallpaperItem + transitions)
│       └── config.qml            # Interface graphique des réglages (Kirigami FormLayout)
└── po/
    ├── template.pot              # Modèle de traduction Gettext extrait
    └── fr.po                     # Fichier source de traduction française
```

### Internationalisation (i18n)

Pour régénérer le template de traduction et recompiler les catalogues (depuis la racine du projet) :

```bash
# 1. Extraction des chaînes traduisibles (template.pot)
xgettext --from-code=UTF-8 --language=JavaScript \
         --keyword=i18nd:2 --keyword=i18ndc:2,3 --keyword=i18ndp:2,3 \
         contents/ui/*.qml contents/ui/*.js -o po/template.pot

# 2. Compilation du fichier binaire .mo
msgfmt po/fr.po -o contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo

# 3. Déploiement dans le répertoire utilisateur
cp contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo ~/.local/share/locale/fr/LC_MESSAGES/
```

### Commandes utiles

- **Vérifier les métadonnées du paquet :**
  ```bash
  kpackagetool6 --type Plasma/Wallpaper --show .
  ```
- **Lister les fonds d'écran installés :**
  ```bash
  kpackagetool6 --type Plasma/Wallpaper --list
  ```
- **Recharger Plasma Shell en direct (sans redémarrer la session) :**
  ```bash
  systemctl --user restart plasma-plasmashell
  ```

---

## Contribution & Communauté

Les contributions sont les bienvenues ! Que ce soit pour signaler un bug, proposer une fonctionnalité, améliorer la
documentation ou ajouter une nouvelle langue :

- 📘 **Guide de contribution :** Consultez [`CONTRIBUTING.md`](CONTRIBUTING.md) pour les prérequis, le workflow de
  développement KDE Plasma 6, les conventions de commits et la gestion des traductions Gettext.
- 🤝 **Code de conduite :** Notre communauté applique les principes du [Contributor Covenant v2.1](CODE_OF_CONDUCT.md).
- 🔒 **Politique de sécurité :** Pour signaler une vulnérabilité de manière responsable, consultez [
  `SECURITY.md`](SECURITY.md).

---

## Licence

Ce projet est un logiciel libre distribué sous licence **GNU General Public License v3.0 or later (GPL-3.0-or-later)**
conformément aux standards de la communauté KDE.  
Consultez le fichier [`LICENSE`](LICENSE) pour le texte intégral des termes et conditions.
