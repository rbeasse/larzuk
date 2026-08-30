-- env.lua

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Certain electron apps (vscode/obsidian) can be blurry due to scaling, this fixes that.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
