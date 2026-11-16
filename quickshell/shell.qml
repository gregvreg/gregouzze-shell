// ==============================================================================
// shell.qml — Main Quickshell entry point for gregouzze-shell
// Orchestrates: StatusBar, DesktopClock, Launcher, WallpaperSelector, PowerMenu
// ==============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    // ── Global state ─────────────────────────────────────────────────────────
    property bool launcherOpen: false
    property bool wallpaperSelectorOpen: false
    property bool powerMenuOpen: false
    property int  activeWorkspace: 1
    property string cpuUsage: "0"
    property string ramUsage: "0G"

    // ── System monitor (reads /proc every 2s) ────────────────────────────────
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            // RAM
            var xhrMem = new XMLHttpRequest();
            xhrMem.open("GET", "file:///proc/meminfo", true);
            xhrMem.onreadystatechange = function() {
                if (xhrMem.readyState === XMLHttpRequest.DONE && xhrMem.status === 200) {
                    var txt = xhrMem.responseText;
                    var total = txt.match(/MemTotal:\s+(\d+)\s+kB/);
                    var avail = txt.match(/MemAvailable:\s+(\d+)\s+kB/);
                    if (total && avail) {
                        var used = parseInt(total[1]) - parseInt(avail[1]);
                        root.ramUsage = (used / 1024 / 1024).toFixed(1) + "G";
                    }
                }
            };
            xhrMem.send();

            // CPU load
            var xhrCpu = new XMLHttpRequest();
            xhrCpu.open("GET", "file:///proc/loadavg", true);
            xhrCpu.onreadystatechange = function() {
                if (xhrCpu.readyState === XMLHttpRequest.DONE && xhrCpu.status === 200) {
                    var parts = xhrCpu.responseText.trim().split(" ");
                    if (parts.length > 0) root.cpuUsage = parts[0];
                }
            };
            xhrCpu.send();
        }
    }

    // ── Workspace tracking via hyprctl ───────────────────────────────────────
    Timer {
        interval: 500; running: true; repeat: true
        onTriggered: {
            workspaceProcess.running = true;
        }
    }

    Process {
        id: workspaceProcess
        command: ["bash", "-c", "hyprctl activeworkspace -j 2>/dev/null | jq -r .id"]
        stdout: StdioCollector {
            onStreamFinished: {
                var ws = parseInt(text.trim());
                if (!isNaN(ws)) root.activeWorkspace = ws;
            }
        }
    }

    // ── Toggle helpers (for keyboard shortcuts and IPC) ──────────────────────
    function toggleLauncher()          { root.launcherOpen = !root.launcherOpen; root.wallpaperSelectorOpen = false; root.powerMenuOpen = false; }
    function toggleWallpaperSelector() { root.wallpaperSelectorOpen = !root.wallpaperSelectorOpen; root.launcherOpen = false; root.powerMenuOpen = false; }
    function togglePowerMenu()         { root.powerMenuOpen = !root.powerMenuOpen; root.launcherOpen = false; root.wallpaperSelectorOpen = false; }

    IpcHandler {
        target: "gregouzze"
        function toggleLauncher(): void { root.toggleLauncher(); }
        function toggleWallpaperSelector(): void { root.toggleWallpaperSelector(); }
        function togglePowerMenu(): void { root.togglePowerMenu(); }
        function themeChanged(): void { /* Matugen rewrites Colors.qml; Quickshell watches it automatically. */ }
    }

    // ======================================================================
    // 1. STATUS BAR
    // ======================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            StatusBar {
                required property var modelData
                screen: modelData

                activeWorkspace: root.activeWorkspace
                cpuUsage: root.cpuUsage
                ramUsage: root.ramUsage

                onLauncherClicked:  root.toggleLauncher()
                onWallpaperClicked: root.toggleWallpaperSelector()
                onPowerClicked:     root.togglePowerMenu()
            }
        }
    }

    // ======================================================================
    // 2. DESKTOP CLOCK
    // ======================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            DesktopClock {
                required property var modelData
                screen: modelData
            }
        }
    }

    // ======================================================================
    // 3. LAUNCHER
    // ======================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Launcher {
                required property var modelData
                screen: modelData
                active: root.launcherOpen
                onDismissed: root.launcherOpen = false
            }
        }
    }

    // ======================================================================
    // 4. WALLPAPER SELECTOR
    // ======================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            WallpaperSelector {
                required property var modelData
                screen: modelData
                active: root.wallpaperSelectorOpen
                onDismissed: root.wallpaperSelectorOpen = false
            }
        }
    }

    // ======================================================================
    // 5. POWER MENU
    // ======================================================================
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PowerMenu {
                required property var modelData
                screen: modelData
                active: root.powerMenuOpen
                onDismissed: root.powerMenuOpen = false
            }
        }
    }
}
