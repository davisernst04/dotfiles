-- Personal configuration migrated from hyprland.conf for Hyprland 0.57.
-- The original .conf files are retained as a recovery reference.
require("host")

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")
hl.env("AQ_NO_MODIFIERS", "1")
hl.monitor({output = "", mode = "preferred", position = "auto", scale = 1})

hl.config({
    ["general.gaps_in"] = 1,
    ["general.gaps_out"] = 1,
    ["general.border_size"] = 1,
    ["general.col.active_border"] = { colors = {"rgba(89b4faff)", "rgba(89b4faff)"}, angle = 45 },
    ["general.col.inactive_border"] = "rgba(00000000)",
    ["general.resize_on_border"] = false,
    ["general.allow_tearing"] = false,
    ["general.layout"] = "dwindle",
    ["decoration.rounding"] = 2,
    ["decoration.active_opacity"] = 1,
    ["decoration.inactive_opacity"] = 1.0,
    ["decoration.shadow.enabled"] = false,
    ["decoration.blur.enabled"] = false,
    ["animations.enabled"] = false,
    ["dwindle.preserve_split"] = true,
    ["master.new_status"] = "master",
    ["misc.force_default_wallpaper"] = 0,
    ["misc.disable_hyprland_logo"] = true,
    ["misc.middle_click_paste"] = false,
    ["misc.focus_on_activate"] = true,
    -- If hyprlock crashes, allow a new locker to take over the session lock
    -- instead of leaving a red "locker crashed" screen that needs a TTY.
    ["misc.allow_session_lock_restore"] = true,
    -- Pressing the current workspace's key returns to the previous workspace.
    ["binds.workspace_back_and_forth"] = true,
    ["input.kb_layout"] = "us",
    ["input.kb_variant"] = "",
    ["input.kb_model"] = "",
    ["input.kb_options"] = "",
    ["input.kb_rules"] = "",
    ["input.accel_profile"] = "flat",
    ["input.follow_mouse"] = 1,
    ["input.sensitivity"] = 0.8,
    ["input.touchpad.natural_scroll"] = true,
    ["input.repeat_delay"] = 150,
    ["input.repeat_rate"] = 50,
})

-- Animations, blur, and shadows are off. The previous curves and per-leaf
-- animation settings remain in hyprland.conf if you ever re-enable them.
-- Disable the leaf too: loop callbacks can keep ticking with global animations off.
hl.animation({leaf = "borderangle", enabled = false})

-- Utility windows float instead of taking half a tiled workspace.
hl.window_rule({
    name = "float-utility-windows",
    match = {class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|xdg-desktop-portal-gtk)$"},
    float = true,
})
-- Apps may not maximize themselves; tiling decides window size.
hl.window_rule({
    name = "suppress-maximize-events",
    match = {class = ".*"},
    suppress_event = "maximize",
})

-- Drop-down scratch terminal: a persistent tmux session ("scratch") for an
-- agent or quick commands, summoned over whatever workspace is visible.
hl.workspace_rule({workspace = "special:scratch", on_created_empty = "kitty -e tmux new-session -A -s scratch"})

hl.bind("SUPER + H", hl.dsp.focus({direction = "left"}))
hl.bind("SUPER + J", hl.dsp.focus({direction = "down"}))
hl.bind("SUPER + K", hl.dsp.focus({direction = "up"}))
hl.bind("SUPER + L", hl.dsp.focus({direction = "right"}))
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({direction = "left"}))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({direction = "down"}))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({direction = "up"}))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({direction = "right"}))
hl.bind("SUPER + ALT + K", hl.dsp.focus({monitor = "u"}))
hl.bind("SUPER + ALT + J", hl.dsp.focus({monitor = "d"}))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({x = 10, y = 0, relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.resize({x = -10, y = 0, relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.resize({x = 0, y = -10, relative = true}), {repeating = true})
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.resize({x = 0, y = 10, relative = true}), {repeating = true})
hl.bind("SUPER + O", hl.dsp.exec_cmd("mkdir -p \"$HOME/Pictures/Screenshots\" && hyprshot -m output -o \"$HOME/Pictures/Screenshots\""))
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("mkdir -p \"$HOME/Pictures/Screenshots\" && hyprshot -m region -o \"$HOME/Pictures/Screenshots\""))
hl.bind("SUPER + CTRL + O", hl.dsp.exec_cmd("mkdir -p \"$HOME/Pictures/Screenshots\" && hyprshot -m window -o \"$HOME/Pictures/Screenshots\""))
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty --start-as normal -o remember_window_size=no"))
hl.bind("SUPER + C", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.window.fullscreen())
hl.bind("SUPER + F", hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + T", hl.dsp.window.float())
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/hypr/rofi-launcher.rasi"))
hl.bind("SUPER + Z", hl.dsp.exec_cmd("~/.config/rofi/powermenu.sh"))
hl.bind("SUPER + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/lock-session"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), {locked = true})
hl.bind("SUPER + P", hl.dsp.exec_cmd("~/.config/waybar/waybar.sh"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("voxtype record toggle"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("voxtype record cancel"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-history"))
hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("scratch"))
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({workspace = "special:scratch"}))
hl.bind("SUPER + 1", hl.dsp.focus({workspace = 1}))
hl.bind("SUPER + 2", hl.dsp.focus({workspace = 2}))
hl.bind("SUPER + 3", hl.dsp.focus({workspace = 3}))
hl.bind("SUPER + 4", hl.dsp.focus({workspace = 4}))
hl.bind("SUPER + 5", hl.dsp.focus({workspace = 5}))
hl.bind("SUPER + 6", hl.dsp.focus({workspace = 6}))
hl.bind("SUPER + 7", hl.dsp.focus({workspace = 7}))
hl.bind("SUPER + 8", hl.dsp.focus({workspace = 8}))
hl.bind("SUPER + 9", hl.dsp.focus({workspace = 9}))
hl.bind("SUPER + 0", hl.dsp.focus({workspace = 10}))
hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({workspace = 1, follow = true}))
hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({workspace = 2, follow = true}))
hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({workspace = 3, follow = true}))
hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({workspace = 4, follow = true}))
hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({workspace = 5, follow = true}))
hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({workspace = 6, follow = true}))
hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({workspace = 7, follow = true}))
hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({workspace = 8, follow = true}))
hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({workspace = 9, follow = true}))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({workspace = 10, follow = true}))
hl.bind("SUPER + mouse_down", hl.dsp.focus({workspace = "e+1"}))
hl.bind("SUPER + mouse_up", hl.dsp.focus({workspace = "e-1"}))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true})
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {mouse = true})
hl.bind("SUPER + F2", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("SUPER + F3", hl.dsp.exec_cmd("wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("SUPER + F1", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("SUPER + F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind("SUPER + F5", hl.dsp.exec_cmd("brightnessctl set 10%-"))
hl.bind("SUPER + F6", hl.dsp.exec_cmd("brightnessctl set +10%"))
hl.bind("SUPER + F11", hl.dsp.exec_cmd("~/.config/hypr/scripts/cycle-keyboard-backlight"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), {repeating = true, locked = true})
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +10%"), {repeating = true, locked = true})
-- Dedicated media keys work with either Fn-lock state and on the lock screen.
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {repeating = true, locked = true})
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), {repeating = true, locked = true})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), {locked = true})
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), {locked = true})

-- Startup callbacks run once per login, not when reloading the configuration.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("~/.config/hypr/scripts/start-session-services")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("swaync")
    hl.exec_cmd("~/.config/hypr/scripts/notification-focus --watch")
    hl.exec_cmd("~/.config/hypr/scripts/clipboard-history --watch")
    hl.exec_cmd("~/.config/waybar/waybar.sh")
end)

hl.bind("CTRL + SHIFT + 2", hl.dsp.global("com.t3tools.T3Code:capture-window"))
