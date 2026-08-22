# Contributing to Dynamic Day & Night Wallpaper

First off, thank you for considering contributing to **Dynamic Day & Night Wallpaper** (`cc.qalpuch.dynamicdaynight`)!
🎉

Contributions from the community are what make open source projects great. Whether you are fixing a bug, proposing a new
feature, improving documentation, or translating into new languages, your help is warmly welcomed.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Reporting Bugs](#reporting-bugs)
- [Proposing Features](#proposing-features)
- [Commit Message Conventions](#commit-message-conventions)
- [Licensing and SPDX Headers](#licensing-and-spdx-headers)
- [Internationalization & Translation Workflow (Gettext)](#internationalization--translation-workflow-gettext)
- [Pull Request Checklist](#pull-request-checklist)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By
participating, you are expected to uphold this code. Please report any unacceptable behavior to
**Q300Zhomas@gmail.com**.

---

## Prerequisites

To contribute to this KDE Plasma 6 wallpaper plugin, ensure you have the following installed on your system:

- **KDE Plasma 6.x** environment (with Qt 6 and KDE Frameworks 6 / Kirigami)
- **`kpackagetool6`** (usually part of `kpackage` / `plasma-workspace`)
- **GNU gettext tools** (`xgettext`, `msgmerge`, `msgfmt`, `msginit`) for translation catalog management
- **Git**
- A code editor supporting QML/JavaScript syntax highlighting (e.g. Kate, VS Code, KDevelop)

---

## Local Development Setup

### 1. Fork and Clone

Clone your fork of the repository locally:

```bash
git clone https://github.com/Q300Z/cc.qalpuch.dynamicdaynight.git
cd cc.qalpuch.dynamicdaynight
```

### 2. Link for Live Development

Create a symbolic link in the user-level Plasma wallpapers directory so your local changes are immediately visible:

```bash
mkdir -p ~/.local/share/plasma/wallpapers
ln -sfn "$(pwd)" ~/.local/share/plasma/wallpapers/cc.qalpuch.dynamicdaynight
```

### 3. Compile Local Translation Catalogs

Compile the `.po` files to binary `.mo` catalogs and deploy them locally:

```bash
mkdir -p contents/locale/fr/LC_MESSAGES ~/.local/share/locale/fr/LC_MESSAGES
msgfmt po/fr.po -o contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo
cp contents/locale/fr/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo ~/.local/share/locale/fr/LC_MESSAGES/
```

*(You can also run `./install.sh` which performs these steps automatically).*

### 4. Testing & Reloading Plasma Shell

To test changes without logging out, restart the Plasma Shell:

```bash
systemctl --user restart plasma-plasmashell
```

To monitor runtime logs and debug messages from QML:

```bash
journalctl --user -u plasma-plasmashell -f
```

You can also run with QML/Qt debug rules enabled:

```bash
QT_LOGGING_RULES="plasma*.debug=true;qml.debug=true" plasmashell --replace
```

---

## Reporting Bugs

Before creating a bug report, please check existing issues to make sure the problem hasn't already been reported.

When creating a bug report, please include:

- **A clear, descriptive title**.
- **Steps to reproduce the issue** with expected vs. actual behavior.
- **Your environment details**:
    - KDE Plasma version (`plasmashell --version`)
    - KDE Frameworks / Qt version
    - Linux distribution and graphics server (Wayland or X11)
    - Screen resolution / multi-monitor setup if relevant
- **Log outputs** from `journalctl --user -u plasma-plasmashell` or terminal.
- **Screenshots or screencasts** if the issue is visual.

---

## Proposing Features

Feature suggestions and enhancements are encouraged! To submit a feature proposal:

- Open an issue describing the proposed feature.
- Explain **why** this feature would be useful and what problem it solves.
- Describe the **proposed user experience / UI** and configuration options if applicable.
- Keep the KDE design philosophy in mind: *Simple by default, powerful when needed*, and adhere to
  the [KDE Human Interface Guidelines (HIG)](https://develop.kde.org/hig/).

---

## Commit Message Conventions

We adhere to the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification. This keeps the
commit history structured and enables automated changelogs.

### Format

```text
<type>(<scope>): <short summary in imperative mood>

[optional body providing more context and rationale]

[optional footer(s) such as Fixes #123 or BREAKING CHANGE: ...]
```

### Allowed Types

- `feat`: A new feature or user-facing enhancement.
- `fix`: A bug fix.
- `docs`: Documentation changes only (e.g. `README.md`, `CONTRIBUTING.md`).
- `style`: Formatting, whitespace, or style changes (no logic changes).
- `refactor`: Code changes that neither fix a bug nor add a feature.
- `perf`: Performance improvements.
- `test`: Adding or updating tests.
- `i18n`: Translation or localization additions/updates.
- `build`: Changes that affect build scripts or packaging.
- `ci`: CI configuration changes.
- `chore`: Maintenance tasks, repo hygiene, dependency updates.

### Examples

```text
feat(solar): implement nautical twilight threshold calculation
fix(config): prevent slider overflow when duration exceeds 5000ms
i18n(po): add German translation catalog (de.po)
docs(contributing): document gettext extraction and compilation workflow
```

---

## Licensing and SPDX Headers

This project is licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**.

All source files (`.qml`, `.js`, `.xml`, `.sh`) must include standard [SPDX License Identifiers](https://spdx.dev/ids/)
following the [REUSE Specification](https://reuse.software/):

```qml
// SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
```

For shell scripts or XML:

```bash
# SPDX-FileCopyrightText: 2026 Q300Z <Q300Zhomas@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
```

---

## Internationalization & Translation Workflow (Gettext)

This project uses the standard KDE gettext domain `plasma_wallpaper_cc.qalpuch.dynamicdaynight`.

In QML and JavaScript files, all user-facing strings must use `i18nd` functions:

```qml
i18nd("plasma_wallpaper_cc.qalpuch.dynamicdaynight", "Morning")
```

### 1. Extract Strings to Template (`po/template.pot`)

When strings are added or modified in `contents/ui/*.qml` or `contents/ui/*.js`, regenerate the template:

```bash
xgettext --from-code=UTF-8 \
         --language=JavaScript \
         --keyword=i18nd:2 \
         --keyword=i18ndc:2,3 \
         --keyword=i18ndp:2,3 \
         contents/ui/*.qml contents/ui/*.js \
         -o po/template.pot
```

### 2. Update Existing Translations (`msgmerge`)

To update an existing language file (e.g. `po/fr.po`) with new strings from `po/template.pot`:

```bash
msgmerge --update po/fr.po po/template.pot
```

### 3. Add a New Language

To initialize a new translation file (e.g., German `de` or Spanish `es`):

```bash
# Using msginit
msginit --input=po/template.pot --locale=de_DE --output-file=po/de.po

# Or copy template manually
cp po/template.pot po/es.po
```

Translate the strings in the `.po` file using a text editor, Lokalize, or Poedit.

### 4. Compile Binary Catalog (`msgfmt`)

Compile the `.po` file into the runtime `.mo` catalog:

```bash
mkdir -p contents/locale/<lang>/LC_MESSAGES
msgfmt po/<lang>.po -o contents/locale/<lang>/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo
```

For system-wide or user test installation:

```bash
mkdir -p ~/.local/share/locale/<lang>/LC_MESSAGES
cp contents/locale/<lang>/LC_MESSAGES/plasma_wallpaper_cc.qalpuch.dynamicdaynight.mo ~/.local/share/locale/<lang>/LC_MESSAGES/
```

---

## Pull Request Checklist

Before submitting a Pull Request (PR), please verify:

1. [ ] **Branching**: Your changes are on a dedicated feature or bugfix branch created from `main`.
2. [ ] **Code Quality**: Code follows KDE QML/JavaScript guidelines, is clean, readable, and properly indented.
3. [ ] **SPDX Headers**: New or modified files include appropriate SPDX copyright and license headers.
4. [ ] **i18n**: All UI strings are wrapped with `i18nd` and `po/template.pot` has been regenerated if UI strings
   changed.
5. [ ] **Testing**: Tested locally on KDE Plasma 6 (Wayland and/or X11) without console errors or regressions.
6. [ ] **Commit Messages**: Commits follow the Conventional Commits specification.
7. [ ] **Documentation**: `README.md` or relevant documentation is updated if new options or dependencies are added.
