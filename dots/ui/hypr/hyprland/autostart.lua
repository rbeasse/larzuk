-- autostart.lua

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("quickshell & hyprpaper")
end)
