-- -----------------------------------------------------
-- Ancient Shell: Hyprland side
-- Load it last, after your own key bindings, with:
--     require("ancient-shell/init")
-- (install.sh links this folder to $XDG_CONFIG_HOME/hypr/ancient-shell and adds
-- that line to hyprland.lua, or to the file given with --entry)
-- -----------------------------------------------------

local palette = require("ancient-shell/palette")

local QS = "qs -c ancient"
local IPC = QS .. " ipc call "

-- On a hybrid laptop (Intel or AMD graphics plus NVIDIA) the shell renders on
-- the integrated GPU, the one Hyprland composites with, even when the session
-- sends apps to the NVIDIA card: screen and window captures (the workspace
-- cube) then share buffers instead of being copied through memory (3 to 5
-- times slower), and the discrete GPU can sleep. Apps the shell opens go
-- through Hyprland, so they still get the session's environment.
local function hybrid_gpu()
	local vendors = {}
	for i = 128, 143 do
		local f = io.open("/sys/class/drm/renderD" .. i .. "/device/vendor")
		if f then
			vendors[f:read("l")] = true
			f:close()
		end
	end
	return vendors["0x10de"] and (vendors["0x8086"] or vendors["0x1002"])
end

local QS_ENV = ""
if hybrid_gpu() then
	QS_ENV = "env __NV_PRIME_RENDER_OFFLOAD=0 __GLX_VENDOR_LIBRARY_NAME=mesa"
		.. " __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json GBM_BACKEND=dri "
end
local QS_START = QS_ENV .. QS .. " -n -d"
-- Boot splash: its own instance, so it shows while the shell is still loading
local CONFIG = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local SPLASH = 'qs -p "' .. CONFIG .. '/quickshell/ancient/splash.qml"'

-- -----------------------------------------------------
-- Autostart
-- -----------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd(SPLASH .. " -d")
	hl.exec_cmd(QS_START)
	-- Dark mode for GTK/libadwaita/Electron apps (read through the settings portal)
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
end)

-- -----------------------------------------------------
-- Dark apps: Qt reads the Ancient palette through qt6ct
-- (install.sh writes ~/.config/qt6ct); GTK 3 gets the dark Adwaita variant
-- -----------------------------------------------------
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ADW_DEBUG_COLOR_SCHEME", "prefer-dark")

-- -----------------------------------------------------
-- Look: stone, glyph light and Atlantis amber
-- -----------------------------------------------------
hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = { colors = { palette.cyan, palette.cyan_deep, palette.amber }, angle = 45 },
			inactive_border = palette.stone_line,
		},
	},
	decoration = {
		rounding = 4,
		active_opacity = 1.0,
		inactive_opacity = 0.92,
		glow = {
			enabled = true,
			range = 12,
			render_power = 3,
			color = palette.cyan_glow,
			color_inactive = "rgba(00000000)",
		},
		shadow = {
			enabled = true,
			range = 24,
			render_power = 3,
			color = "rgba(000000aa)",
		},
		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			vibrancy = 0.18,
		},
	},
})

-- The shell draws its own transitions; blur what sits behind its panels
hl.layer_rule({
	match = { namespace = "^ancient-(bar|drawer|notifications|osd|launcher|wallpicker)$" },
	blur = true,
	ignore_alpha = 0.3,
	no_anim = true,
})
hl.layer_rule({ match = { namespace = "^ancient-(wallpaper|splash|cube)$" }, no_anim = true })

-- NetworkManager tools float centred instead of tiling: the connection editor
-- (opened from the control centre), nm-applet's dialogs and VPN login dialogs
local NM_WINDOWS = "^(nm-connection-editor|nm-applet|nm-.*-auth-dialog)$"
hl.window_rule({ match = { class = NM_WINDOWS }, float = true })
hl.window_rule({ match = { class = NM_WINDOWS }, center = true })

-- -----------------------------------------------------
-- Key bindings (replace whatever the config had bound to these keys)
-- -----------------------------------------------------
local mainMod = "SUPER"

local function rebind(keys, cmd, desc)
	hl.unbind(keys)
	hl.bind(keys, hl.dsp.exec_cmd(cmd), { description = desc })
end

rebind(mainMod .. " + D", IPC .. "shell launcher", "Open the application launcher")
rebind(mainMod .. " + A", IPC .. "shell dashboard", "Toggle the dashboard")
rebind(mainMod .. " + N", IPC .. "shell control", "Toggle the control centre")
rebind(mainMod .. " + CTRL + Q", IPC .. "shell session", "Open the session menu")
rebind(mainMod .. " + CTRL + W", IPC .. "shell wallpapers", "Open the wallpaper selector")
rebind(mainMod .. " + SHIFT + W", IPC .. "wallpaper random", "Random wallpaper")
rebind(mainMod .. " + SHIFT + B", QS .. " kill; " .. QS_START, "Restart the shell")
rebind(mainMod .. " + CTRL + B", IPC .. "shell closeAll", "Close shell overlays")
rebind(mainMod .. " + ALT + N", IPC .. "shell dnd", "Toggle do not disturb")

-- Workspaces through the shell, which turns the switch into a cube
-- (quickshell/ancient/workspace). The keys call the shell's global shortcuts
-- while its bar is up and fall back to plain Hyprland switching when the shell
-- is not running, so they never stop working.
local function shell_running()
	return #hl.get_layers({ namespace = "ancient-bar" }) > 0
end

local function via_shell(shortcut, fallback)
	return function()
		if shell_running() then
			hl.dispatch(hl.dsp.global("ancient:" .. shortcut))
		else
			hl.dispatch(fallback)
		end
	end
end

local function rebind_workspace(keys, target, desc)
	hl.unbind(keys)
	hl.bind(keys, via_shell("go-" .. target, hl.dsp.focus({ workspace = target })), { description = desc })
end

local function rebind_move(keys, target, desc)
	hl.unbind(keys)
	hl.bind(keys, via_shell("move-" .. target, hl.dsp.window.move({ workspace = target, follow = true })),
		{ description = desc })
end

local numpad = { "KP_End", "KP_Down", "KP_Next", "KP_Left", "KP_Begin", "KP_Right", "KP_Home", "KP_Up", "KP_Prior", "KP_Insert" }
for n = 1, 10 do
	local ws = tostring(n)
	local key = tostring(n % 10)
	rebind_workspace(mainMod .. " + " .. key, ws, "Open workspace " .. ws)
	rebind_workspace(mainMod .. " + " .. numpad[n], ws, "Open workspace " .. ws)
	rebind_move(mainMod .. " + SHIFT + " .. key, ws, "Move active window to workspace " .. ws)
	rebind_move(mainMod .. " + SHIFT + " .. numpad[n], ws, "Move active window to workspace " .. ws)
end
rebind_workspace(mainMod .. " + Tab", "m+1", "Open next workspace")
rebind_workspace(mainMod .. " + SHIFT + Tab", "m-1", "Open previous workspace")
rebind_workspace(mainMod .. " + mouse_down", "e+1", "Open next workspace")
rebind_workspace(mainMod .. " + mouse_up", "e-1", "Open previous workspace")

-- Closing the active window through the shell, which sucks it into a stargate
-- (quickshell/ancient/windowfx); plain close when the shell is not running
hl.unbind(mainMod .. " + Q")
hl.bind(mainMod .. " + Q", via_shell("close-window", hl.dsp.window.close()), { description = "Close the active window" })

-- Brightness through the shell so the OSD shows (volume keys already do)
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(IPC .. "brightness up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(IPC .. "brightness down"), { locked = true, repeating = true })
