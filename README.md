# Gregouzze Shell

Un *rice* Arch Linux / Hyprland sur mesure, modulaire et orienté développement (inspiré de l'esprit Caelestia Shell). Conçu pour associer un environnement de code épuré à un système de thétisation dynamique basé sur le fond d'écran.

## 🚀 Stack Technique

- **Window Manager :** Hyprland (avec gestion dynamique des gaps et bordures)
- **Shell & Widgets :** Quickshell (QML / Qt6) pour une interface ultra-fluide[cite: 1]
- **Moteur de couleurs :** Matugen (Material You, mode sombre forcé pour le confort de code)[cite: 1]
- **Gestionnaire de fonds d'écran :** `swww` (pour des transitions de wallpapers fluides)[cite: 1]
- **Terminal :** Kitty[cite: 1]

## 📁 Structure du Projet

```text
~/.config/gregouzze-shell/
├── hypr/               # Configurations Hyprland modulaires (keybinds, rules, colors.conf généré)
├── quickshell/         # Composants QML de l'interface (barre, widgets, sélecteur de wallpaper)
├── matugen/            # Fichiers de configuration et templates (Hyprland, Kitty, Quickshell)
├── scripts/            # Scripts d'orchestration (ex: wall-switch.sh)
└── install.sh          # Script d'installation automatique et de création des symlinks 
