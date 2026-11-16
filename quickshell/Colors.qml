// ==============================================================================
// Auto-generated Quickshell Colors Singleton by Matugen
// Theme: Material You (Dark Mode Forced) - gregouzze-shell
// ==============================================================================

pragma Singleton
import QtQuick

QtObject {
    id: root

    // Theme Mode
    readonly property string mode: "dark"

    // Core Surfaces & Backgrounds
    readonly property color background: "#121318"
    readonly property color contentBackground: "#e3e1e9"
    readonly property color surface: "#121318"
    readonly property color contentSurface: "#e3e1e9"
    readonly property color surfaceVariant: "#45464f"
    readonly property color contentSurfaceVariant: "#c6c5d0"
    readonly property color surfaceContainerLowest: "#0d0e13"
    readonly property color surfaceContainerLow: "#1b1b21"
    readonly property color surfaceContainer: "#1f1f25"
    readonly property color surfaceContainerHigh: "#292a2f"
    readonly property color surfaceContainerHighest: "#34343a"

    // Primary Accents
    readonly property color primary: "#b9c3ff"
    readonly property color contentPrimary: "#212c61"
    readonly property color primaryContainer: "#384379"
    readonly property color contentPrimaryContainer: "#dee1ff"

    // Secondary Accents
    readonly property color secondary: "#c3c5dd"
    readonly property color contentSecondary: "#2c2f42"
    readonly property color secondaryContainer: "#434659"
    readonly property color contentSecondaryContainer: "#dfe1f9"

    // Tertiary Accents
    readonly property color tertiary: "#e5bad8"
    readonly property color contentTertiary: "#44263e"
    readonly property color tertiaryContainer: "#5c3c55"
    readonly property color contentTertiaryContainer: "#ffd7f2"

    // Outlines & Borders
    readonly property color outline: "#90909a"
    readonly property color outlineVariant: "#45464f"

    // Semantic States
    readonly property color error: "#ffb4ab"
    readonly property color contentError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color contentErrorContainer: "#ffdad6"
    readonly property color shadow: "#000000"
    readonly property color scrim: "#000000"

    // UI Convenience Aliases (for Caelestia / modern QML widgets)
    readonly property color accent: primary
    readonly property color contentAccent: contentPrimary
    readonly property color bg: surface
    readonly property color fg: contentSurface
    readonly property color borderActive: primary
    readonly property color borderInactive: outlineVariant

    // Helper: Returns a copy of the input color with an overridden alpha channel (0.0 to 1.0)
    function withAlpha(baseColor: color, alphaValue: real): color {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Math.max(0.0, Math.min(1.0, alphaValue)));
    }
}
