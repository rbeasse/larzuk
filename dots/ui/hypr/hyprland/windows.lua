-- windows.lua
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Popup floating windows (TUI apps from waybar)
hl.window_rule({
    name  = "popup-float",
    match = { class = "popup" },

    float  = true,
    center = true,
    size   = "900 600",
})
