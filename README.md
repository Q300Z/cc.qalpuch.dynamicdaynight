# Fond d'écran dynamique Jour & Nuit (KDE Plasma 6)

Plugin de fond d'écran dynamique pour **KDE Plasma 6** (`cc.qalpuch.dynamicdaynight`) qui adapte automatiquement votre fond d'écran selon le cycle de la journée (**Matin**, **Midi**, **Soir**, **Nuit**), avec transition fluide en fondu enchaîné (*crossfade*), calculs astronomiques de la position solaire et personnalisation complète.

---

## Sommaire

- [Présentation](#présentation)
- [Fonctionnalités](#fonctionnalités)
- [Installation manuelle](#installation-manuelle)
- [Utilisation](#utilisation)
- [Développement & Architecture](#développement--architecture)
  - [Structure du projet](#structure-du-projet)
  - [Internationalisation (i18n)](#internationalisation-i18n)
  - [Commandes utiles](#commandes-utiles)
- [Licence](#licence)

---

## Présentation

Ce plugin est conçu nativement pour **KDE Plasma 6** (Qt 6 / KF6) selon les standards et conventions de la communauté KDE :
- **Clé en main (*Out-of-the-box*) :** Embarque 4 illustrations haute qualité pour chaque moment de la journée.
- **Calculs solaires automatiques :** Calcule les heures réelles du lever, du zénith, du coucher de soleil et du crépuscule en fonction du fuseau horaire de votre système (algorithme éphémérides solaires NOAA 100% hors-ligne).
- **Transitions douces :** Animation de fondu réglable (*crossfade*) pour éviter tout changement brusque.
- **Respect des principes KISS & DRY :** Code modulaire, séparation stricte des responsabilités (logique métier dans `TimeUtils.js`, schéma KConfigXT dans `main.xml`, interface déclarative dans `config.qml`).

---

## Fonctionnalités

- ☀️ **Détection solaire automatique :** Synchronisation sur le cycle réel du soleil sans connexion Internet requise.
- 🕒 **Mode horaire manuel :** Possibilité de définir des plages horaires fixes personnalisées.
- 🖼️ **Images personnalisables :** Remplacement possible de chaque image (Matin, Midi, Soir, Nuit) via un sélecteur de fichier avec bouton de réinitialisation.
- 🎨 **Modes de remplissage :** Étiré, Recadré / Zoom (conserve les proportions), Ajusté.
- ⏱️ **Durée de transition ajustable :** Réglage précis de la durée du fondu (en ms).
- 🌍 **Internationalisation (i18n) :** Support multilingue complet (Français et Anglais inclus).
- 🔄 **Bouton de réinitialisation :** Restauration des réglages d'origine en un seul clic.

---

## Installation manuelle

### Méthode 1 : Lien symbolique de développement (Recommandé)

Pour lier le dossier directement dans l'environnement utilisateur Plasma :

```bash
# 1. Créer les dossiers de destination
mkdir -p ~/.local/share/plasma/wallpapers
mkdir -p ~/.local/share/locale/fr/LC_MESSAGES

# 2. Créer le lien symbolique du plugin
ln -sfn /chemin/vers/wallpaper ~/.local/share/plasma/wallpapers/cc.qalpuch.dynamicdaynight

# 3. Installer le catalogue de traduction française
cp contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo ~/.local/share/locale/fr/LC_MESSAGES/
```

### Méthode 2 : Installation via `kpackagetool6`

```bash
kpackagetool6 --type Plasma/Wallpaper --install /chemin/vers/wallpaper
```

Pour mettre à jour un paquet déjà installé :
```bash
kpackagetool6 --type Plasma/Wallpaper --upgrade /chemin/vers/wallpaper
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
├── metadata.json                 # Métadonnées du KPackage Plasma 6 (Id: cc.qalpuch.dynamicdaynight)
├── README.md                     # Documentation du projet
├── contents/
│   ├── config/
│   │   └── main.xml              # Schéma KConfigXT des paramètres utilisateur
│   ├── images/
│   │   ├── matin.png             # Image du matin (par défaut 06:00 -> 11:59)
│   │   ├── midi.png              # Image du midi (par défaut 12:00 -> 17:59)
│   │   ├── soir.png              # Image du soir (par défaut 18:00 -> 21:59)
│   │   └── nuit.png              # Image de nuit (par défaut 22:00 -> 05:59)
│   ├── locale/
│   │   └── fr/LC_MESSAGES/       # Catalogue binaire Gettext (.mo) compilé
│   └── ui/
│       ├── TimeUtils.js          # Module métier (éphémérides solaires et résolutions)
│       ├── main.qml              # Vue principale (WallpaperItem + transitions)
│       └── config.qml            # Interface graphique des réglages (Kirigami FormLayout)
└── po/
    ├── template.pot              # Modèle de traduction Gettext extrait
    └── fr.po                     # Fichier source de traduction française
```

### Internationalisation (i18n)

Pour régénérer le template de traduction et recompiler les catalogues :

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

## Licence

Ce projet est distribué sous licence **GPL-3.0-or-later** conformément aux standards du projet KDE.  
Auteur : **Q300Z** (<Q300Zhomas@gmail.com>) - [https://qalpuch.cc](https://qalpuch.cc)
