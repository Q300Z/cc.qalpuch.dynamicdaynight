## Description

<!-- Résumez brièvement les changements introduits par cette Pull Request et leur motivation. -->

## Type de changement

- [ ] 🐛 Correction de bug (`fix`)
- [ ] ✨ Nouvelle fonctionnalité (`feat`)
- [ ] ♻️ Refactorisation / Optimisation (`refactor`)
- [ ] 📝 Documentation (`docs`)
- [ ] 🌐 Internationalisation / Traduction (`i18n`)
- [ ] 🔧 Maintenance / CI / Outils (`chore`)

## Référence(s) liée(s)

<!-- Indiquez les issues fermées ou associées, ex: Fixes #123 ou Closes #456 -->
Closes #

## Captures d'écran / Démonstration (optionnel)

<!-- Si la modification impacte l'interface utilisateur ou les transitions, ajoutez une capture ou un GIF. -->

## Checklist

Avant de soumettre cette Pull Request, assurez-vous d'avoir validé les points suivants :

- [ ] **Code de Conduite** : J'ai lu et j'accepte de respecter le code de conduite du projet.
- [ ] **Conventional Commits** : Mes messages de commit respectent le standard [Conventional Commits](https://www.conventionalcommits.org/) (ex: `feat: ...`, `fix: ...`, `chore: ...`).
- [ ] **En-têtes SPDX** : Tous les fichiers créés ou modifiés contiennent les en-têtes de copyright et licence SPDX appropriés (`SPDX-FileCopyrightText` et `SPDX-License-Identifier`).
- [ ] **Tests sous KDE Plasma 6** : Les modifications ont été testées et fonctionnent correctement sous KDE Plasma 6 (Wayland et/ou X11).
- [ ] **Internationalisation (i18n)** : Les chaînes traduisibles ont été mises à jour dans `po/template.pot` et les catalogues `po/*.po` si applicable.
- [ ] **Validation locale** : Les validateurs locaux (`jq`, `xmllint`, `msgfmt --check`) et le script `install.sh` s'exécutent sans erreur.
