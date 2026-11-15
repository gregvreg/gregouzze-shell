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
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color onBackground: "{{colors.on_background.default.hex}}"
    readonly property color surface: "{{colors.surface.default.hex}}"
    readonly property color onSurface: "{{colors.on_surface.default.hex}}"
    readonly property color surfaceVariant: "{{colors.surface_variant.default.hex}}"
    readonly property color onSurfaceVariant: "{{colors.on_surface_variant.default.hex}}"
    readonly property color surfaceContainerLowest: "{{colors.surface_container_lowest.default.hex}}"
    readonly property color surfaceContainerLow: "{{colors.surface_container_low.default.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.default.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceContainerHighest: "{{colors.surface_container_highest.default.hex}}"

    // Primary Accents
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color onPrimary: "{{colors.on_primary.default.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"

    // Secondary Accents
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color onSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color secondaryContainer: "{{colors.secondary_container.default.hex}}"
    readonly property color onSecondaryContainer: "{{colors.on_secondary_container.default.hex}}"

    // Tertiary Accents
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"
    readonly property color onTertiary: "{{colors.on_tertiary.default.hex}}"
    readonly property color tertiaryContainer: "{{colors.tertiary_container.default.hex}}"
    readonly property color onTertiaryContainer: "{{colors.on_tertiary_container.default.hex}}"

    // Outlines & Borders
    readonly property color outline: "{{colors.outline.default.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.default.hex}}"

    // Semantic States
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color onError: "{{colors.on_error.default.hex}}"
    readonly property color errorContainer: "{{colors.error_container.default.hex}}"
    readonly property color onErrorContainer: "{{colors.on_error_container.default.hex}}"
    readonly property color shadow: "{{colors.shadow.default.hex}}"
    readonly property color scrim: "{{colors.scrim.default.hex}}"

    // UI Convenience Aliases (for Caelestia / modern QML widgets)
    readonly property color accent: primary
    readonly property color onAccent: onPrimary
    readonly property color bg: surface
    readonly property color fg: onSurface
    readonly property color borderActive: primary
    readonly property color borderInactive: outlineVariant

    // Helper: Returns a copy of the input color with an overridden alpha channel (0.0 to 1.0)
    function withAlpha(baseColor: color, alphaValue: real): color {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, Math.max(0.0, Math.min(1.0, alphaValue)));
    }
}
