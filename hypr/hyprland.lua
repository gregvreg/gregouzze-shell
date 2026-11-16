-- gregouzze-shell integration for Hyprland's native Lua configuration.
local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local shellConfig = configHome .. "/gregouzze-shell"

-- Quickshell daemonizes so it stays alive independently from any terminal.
hl.on("hyprland.start", function()
  hl.exec_cmd("quickshell -d -p " .. shellConfig .. "/quickshell/shell.qml")
end)

local mainMod = _G.mainMod or "SUPER"
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell ipc call gregouzze toggleLauncher"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("quickshell ipc call gregouzze toggleWallpaperSelector"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("quickshell ipc call gregouzze togglePowerMenu"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(shellConfig .. "/scripts/wall-switch.sh"))
