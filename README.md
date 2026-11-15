<div align="center">

# 🌌 gregouzze-shell

**A modular, developer-oriented Arch Linux & Hyprland desktop shell with dynamic Material You theming.**  
*Inspired by the sleek aesthetics and fluidity of Caelestia Shell.*

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-00AAFF?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org/)
[![Quickshell](https://img.shields.io/badge/Quickshell-Qt6_QML-41CD52?style=for-the-badge&logo=qt&logoColor=white)](https://quickshell.outfoxxed.me/)
[![Matugen](https://img.shields.io/badge/Matugen-Material_You-E91E63?style=for-the-badge)](https://github.com/InioX/matugen)
[![swww](https://img.shields.io/badge/swww-Wayland_Transitions-8A2BE2?style=for-the-badge)](https://github.com/LGFae/swww)
[![Kitty](https://img.shields.io/badge/Kitty-GPU_Terminal-000000?style=for-the-badge&logo=kitty&logoColor=white)](https://sw.kovidgoyal.net/kitty/)

---

[Key Features](#-key-features) • [Tech Stack](#-technical-stack) • [Color Pipeline](#-dynamic-color-pipeline) • [Directory Structure](#-project-structure) • [Installation](#-installation) • [Usage](#-usage--management) • [Keybindings](#-default-keybindings)

</div>

---

## 🌟 Key Features

- **🌙 Dark Mode by Default :** Palette de couleurs Material You extraite dynamiquement de vos fonds d'écran, rigoureusement verrouillée en mode sombre pour préserver vos yeux lors des longues sessions de code.
- **✨ Transitions Fluides Wayland :** Changement de fond d'écran sans accroc propulsé par `swww` (animations *grow*, *fade*, *wipe*, *wave* configurables à 60 FPS).
- **⚡ Quickshell (Qt6 / QML) :** Interface utilisateur légère, modulaire et native Wayland (barre d'état, widgets, intégration directe du singleton `Colors.qml`).
- **🔄 Rechargement à Chaud Intégral :** Un seul script (`scripts/wall-switch.sh`) synchronise instantanément le wallpaper, Hyprland, Kitty et Quickshell sans redémarrage de session.
- **🛠 Installateur & Gestionnaire Intelligent :** Script `install.sh` tout-en-un offrant un menu interactif (TUI), la vérification des dépendances pacman/AUR, la création sécurisée de symlinks avec sauvegardes automatiques, et un mode `--update` / `--info`.

---

## 🚀 Technical Stack

| Composant | Rôle | Caractéristiques clés |
| :--- | :--- | :--- |
| **[Hyprland](https://hyprland.org/)** | Dynamic Tiling Compositor | Gaps personnalisés, animations lisses, bordures dynamiques synchronisées |
| **[Quickshell](https://quickshell.outfoxxed.me/)** | Shell UI Framework | Architecture déclarative Qt6/QML, performance native, couche Wayland LayerShell |
| **[Matugen](https://github.com/InioX/matugen)** | Material 3 Color Generator | Algorithme M3, sélection automatique du ton dominant, rendu multi-templates |
| **[swww](https://github.com/LGFae/swww)** | Animated Wallpaper Daemon | Transitions spatiales fluides, très faible empreinte mémoire sur Wayland |
| **[Kitty](https://sw.kovidgoyal.net/kitty/)** | GPU-accelerated Terminal | Support Base16 & Material You, rechargement à chaud instantané via `SIGUSR1` |

---

## 🎨 Dynamic Color Pipeline

Le flux d'orchestration transforme n'importe quelle image en un écosystème cohérent en moins d'une seconde :

```
┌─────────────────────────────────┐
│       Wallpaper Selection       │  (PNG / JPG / WEBP)
└────────────────┬────────────────┘
                 │
                 ▼
     ┌───────────────────────┐
     │  scripts/wall-switch  │
     └───────┬───────┬───────┘
             │       │
    ┌────────┘       └────────┐
    ▼                         ▼
┌───────────────┐     ┌───────────────┐
│  swww daemon  │     │    matugen    │  (Mode: Dark forced)
│  (Transition) │     │ (config.toml) │
└───────────────┘     └───────┬───────┘
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
  ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
  │ Hyprland Conf │   │  Kitty Theme  │   │  Quickshell   │
  │ (colors.conf) │   │ (colors.conf) │   │ (Colors.qml)  │
  └───────┬───────┘   └───────┬───────┘   └───────┬───────┘
          │                   │                   │
          ▼                   ▼                   ▼
  hyprctl reload         pkill -SIGUSR1      QML Hot-Reload
  (Bordures actives)    (Palette terminal)  (Widgets & Bar)
```

---

## 📁 Project Structure

```text
~/.config/gregouzze-shell/
├── hypr/
│   ├── hyprland.conf            # Configuration principale Hyprland modulaire
│   ├── colors.conf              # Variables de couleurs générées par Matugen
│   ├── keybinds.conf            # Raccourcis clavier (Kitty, scripts, workspaces)
│   └── rules.conf               # Règles de fenêtres, opacité et flou Quickshell
├── quickshell/
│   ├── shell.qml                # Point d'entrée de la barre et widgets Quickshell
│   ├── Colors.qml               # Singleton QML de couleurs avec helpers alpha
│   ├── qmldir                   # Déclaration du singleton Colors pour QtQuick
│   └── colors.json              # Export JSON brut des palettes pour scripts externes
├── matugen/
│   ├── config.toml              # Configuration centrale Matugen (dark mode, hooks)
│   └── templates/
│       ├── hyprland-colors.conf # Template de variables Hyprland
│       ├── kitty-colors.conf    # Template de palette Kitty (Base16 + M3)
│       ├── quickshell-colors.qml# Template du singleton Qt6/QML
│       └── quickshell-colors.json# Template JSON
├── kitty/
│   ├── kitty.conf               # Configuration de base Kitty (polices, marges)
│   └── colors.conf              # Thème dynamique importé
├── scripts/
│   └── wall-switch.sh           # Script d'application swww + orchestration Matugen
├── install.sh                   # Installateur, gestionnaire de symlinks & CLI d'info
└── README.md                    # Documentation complète du projet
```

---

## 📦 Installation

### 1. Installation Rapide (One-Liner)

Clonez le dépôt dans votre répertoire `~/.config/gregouzze-shell` et lancez l'installateur :

```bash
git clone https://github.com/gregouzze/gregouzze-shell.git ~/.config/gregouzze-shell && ~/.config/gregouzze-shell/install.sh --install
```

### 2. Dépendances Requises (Arch Linux)

L'installateur peut installer automatiquement les paquets nécessaires via votre helper AUR (`paru` ou `yay`), ou vous pouvez les installer à la main :

```bash
# Paquets officiels (Pacman)
sudo pacman -S --needed hyprland kitty jq libnotify socat qt6-declarative qt6-wayland

# Paquets AUR
yay -S --needed quickshell-git matugen-bin swww
# ou avec paru :
# paru -S --needed quickshell-git matugen-bin swww
```

---

## 🕹 Usage & Management

Le script `install.sh` sert à la fois d'installateur, d'utilitaire de maintenance et de tableau de bord.

### Menu Interactif (TUI)
Lancez simplement le script sans arguments pour ouvrir l'interface texte :
```bash
~/.config/gregouzze-shell/install.sh
```

### Options CLI

| Commande | Action |
| :--- | :--- |
| `./install.sh -i` / `--install` | Vérification complète des dépendances, création des symlinks et génération de la palette initiale |
| `./install.sh -u` / `--update` | Exécute un `git pull --rebase`, rafraîchit les liens symboliques et recharge les composants |
| `./install.sh -s` / `--info` | Affiche l'état du shell, la version git, les binaires actifs et les raccourcis configurés |
| `./install.sh -l` / `--links` | Re-crée les liens symboliques vers `~/.config/hypr`, `~/.config/kitty`, etc. avec sauvegarde automatique |
| `./install.sh -h` / `--help` | Affiche l'aide et les options disponibles |

### Changer de Wallpaper & de Thème à la volée

Pour changer d'ambiance et régénérer instantanément tout le shell :

```bash
# Application standard (transition 'grow' fluide)
~/.config/gregouzze-shell/scripts/wall-switch.sh ~/Pictures/wallpapers/neon-city.png

# Choisir une transition personnalisée (grow, fade, wipe, wave, outer, center)
~/.config/gregouzze-shell/scripts/wall-switch.sh -t wave ~/Pictures/wallpapers/cyberpunk.png

# Régler la durée de la transition (ex: 2.0 secondes)
~/.config/gregouzze-shell/scripts/wall-switch.sh -t fade -d 2.0 ~/Pictures/wallpapers/nature.jpg
```

---

## ⌨️ Default Keybindings

| Raccourci | Action |
| :--- | :--- |
| `Super + Return` | Ouvrir le terminal **Kitty** |
| `Super + Space` | Ouvrir le lanceur d'applications (**Quickshell** / Rofi / Wofi) |
| `Super + W` | Lancer le sélecteur / rafraîchissement de wallpaper |
| `Super + Q` | Fermer la fenêtre active |
| `Super + M` | Quitter la session Hyprland |
| `Super + F` | Basculer en plein écran (*Fullscreen*) |
| `Super + V` | Basculer en mode flottant (*Toggle Floating*) |
| `Super + [H / J / K / L]` | Déplacer le focus (Gauche / Bas / Haut / Droite - touches Vim) |
| `Super + 1..9` | Basculer vers l'espace de travail 1 à 9 |
| `Super + Shift + 1..9` | Déplacer la fenêtre vers l'espace de travail 1 à 9 |
| `Super + Clic Gauche` | Déplacer une fenêtre avec la souris |
| `Super + Clic Droit` | Redimensionner une fenêtre avec la souris |

---

## 🧩 Quickshell QML Integration

Le singleton de couleurs généré dans `quickshell/Colors.qml` est directement disponible dans tous vos composants QML :

```qml
import QtQuick
import Quickshell

Rectangle {
    // Fond dynamique avec effet de transparence
    color: Colors.withAlpha(Colors.surfaceContainer, 0.85)
    
    // Bordure réactive basée sur la couleur primaire
    border.color: Colors.primary
    border.width: 1
    radius: 10

    Text {
        anchors.centerIn: parent
        text: "Hello from gregouzze-shell!"
        color: Colors.onSurface
    }
}
```

---

## 🤝 Remerciements & Inspirations

- **[Caelestia Shell](https://github.com/caelestia-dots)** : Pour l'inspiration architecturale et le raffinement visuel.
- **[Outfoxxed / Quickshell](https://quickshell.outfoxxed.me/)** : Pour le framework shell le plus rapide et flexible sous Wayland.
- **[InioX / Matugen](https://github.com/InioX/matugen)** : Pour le générateur de palettes Material You de référence sous Linux.
- **[Vaxry & la communauté Hyprland](https://hyprland.org/)** : Pour un compositeur Wayland moderne et ultra-performant.

---

<div align="center">
<sub>Conçu avec soin pour Arch Linux & Hyprland • gregouzze-shell</sub>
</div>
