-- ui/tokens.lua
-- Design System Tokens for LogicTales UI
-- "Bold Kids Blocky" visual direction

local Tokens = {}

-- Virtual resolution (base design size)
Tokens.VIRTUAL_WIDTH = 1280
Tokens.VIRTUAL_HEIGHT = 720

-- Spacing scale (8px base)
Tokens.SPACING = {
    xs = 8,      -- Minimum internal padding
    sm = 16,     -- Standard element padding
    md = 24,     -- Gap between related elements
    lg = 32,     -- Gap between sections
    xl = 40,     -- Touch target gap for kids
    xxl = 48,    -- Major section dividers
}

-- Touch targets (kids-friendly - generous sizing)
Tokens.TOUCH = {
    min_target = 48,           -- Minimum touch target (Material Design standard)
    recommended_target = 64,   -- Recommended for kids 6-8
    min_gap = 16,              -- Minimum gap between targets
    recommended_gap = 24,      -- Recommended gap for kids
    button_min_width = 120,    -- Minimum button width for labels
    button_min_height = 52,    -- Minimum button height
    primary_button_width = 200,
    primary_button_height = 60,
}

-- Borders (thick for "blocky" aesthetic)
Tokens.BORDERS = {
    thin = 2,      -- Subtle separation
    medium = 4,    -- Standard panel borders
    thick = 6,     -- Interactive element emphasis
    heavy = 8,     -- Primary buttons, focused elements
}

-- Elevation (pixel-art style - offset shadows, no blur)
Tokens.ELEVATION = {
    none = {border = 0, offset = 0},
    low = {border = 2, offset = 2},      -- Subtle depth
    medium = {border = 4, offset = 4},   -- Card/panel depth
    high = {border = 6, offset = 6},     -- Modal/popup depth
}

-- Colors (bright playful palette)
Tokens.COLORS = {
    -- Backgrounds
    background = {0.15, 0.15, 0.20, 1.0},         -- Dark slate
    surface = {0.22, 0.22, 0.28, 1.0},            -- Panel background
    surface_elevated = {0.28, 0.28, 0.35, 1.0},   -- Raised panels

    -- Primary (sky blue)
    primary = {0.30, 0.65, 0.90, 1.0},
    primary_dark = {0.20, 0.50, 0.75, 1.0},
    primary_light = {0.45, 0.75, 0.95, 1.0},

    -- Secondary (warm orange)
    secondary = {0.95, 0.70, 0.20, 1.0},
    secondary_dark = {0.75, 0.55, 0.15, 1.0},
    secondary_light = {1.0, 0.80, 0.40, 1.0},

    -- Text
    text_primary = {1.0, 1.0, 1.0, 1.0},          -- White
    text_secondary = {0.75, 0.75, 0.80, 1.0},     -- Light gray
    text_disabled = {0.50, 0.50, 0.55, 1.0},      -- Dim gray
    text_on_primary = {1.0, 1.0, 1.0, 1.0},       -- White on colored bg
    text_on_secondary = {0.15, 0.15, 0.20, 1.0},  -- Dark on orange

    -- Feedback
    success = {0.30, 0.80, 0.40, 1.0},            -- Bright green
    success_dark = {0.20, 0.60, 0.30, 1.0},
    error = {0.90, 0.35, 0.35, 1.0},              -- Coral red
    error_dark = {0.70, 0.25, 0.25, 1.0},
    warning = {0.95, 0.85, 0.30, 1.0},            -- Yellow

    -- Accent (focus ring, highlights)
    accent = {0.85, 0.45, 0.85, 1.0},             -- Purple/magenta
    accent_dark = {0.65, 0.30, 0.65, 1.0},

    -- Shadow (for offset drop shadows)
    shadow = {0.08, 0.08, 0.10, 0.8},

    -- Input fields
    input_bg = {0.18, 0.18, 0.23, 1.0},
    input_border = {0.40, 0.40, 0.45, 1.0},
    input_border_focus = {0.30, 0.65, 0.90, 1.0}, -- Primary color

    -- Warm Storybook Theme
    warm_cream = {0.96, 0.91, 0.82, 1.0},         -- Warm cream background
    warm_brown = {0.55, 0.35, 0.20, 1.0},         -- Cozy brown (wood/trunk)
    warm_orange = {0.95, 0.60, 0.30, 1.0},        -- Sunset orange accent
    forest_green = {0.25, 0.50, 0.30, 1.0},       -- Tree/nature green
    sky_blue_soft = {0.60, 0.80, 0.95, 1.0},      -- Soft sky blue

    -- Decoration colors (pixel-art elements)
    deco_tree_trunk = {0.45, 0.30, 0.18, 1.0},    -- Tree trunk brown
    deco_tree_dark = {0.20, 0.40, 0.25, 1.0},     -- Dark foliage
    deco_tree_light = {0.35, 0.55, 0.35, 1.0},    -- Light foliage
    deco_star = {1.0, 0.95, 0.70, 1.0},           -- Warm star/sparkle
    deco_circle = {0.85, 0.55, 0.35, 0.3},        -- Soft orange circle

    -- Semi-transparent panel backgrounds (for Slab)
    panel_dark_transparent = {0.12, 0.12, 0.16, 0.88},
    panel_medium_transparent = {0.18, 0.18, 0.22, 0.90},
    panel_light_transparent = {0.22, 0.22, 0.28, 0.85},

    -- Dream It button
    dream_button = {0.50, 0.35, 0.60, 1.0},       -- Purple magic
    dream_button_hover = {0.60, 0.45, 0.70, 1.0},
}

-- Typography (sizes for different text roles)
Tokens.TYPOGRAPHY = {
    title = {
        size = 32,
        weight = "bold",
        line_height = 40,
    },
    heading = {
        size = 24,
        weight = "bold",
        line_height = 32,
    },
    body = {
        size = 18,
        weight = "normal",
        line_height = 24,
    },
    body_large = {
        size = 20,
        weight = "normal",
        line_height = 28,
    },
    button = {
        size = 20,
        weight = "bold",
        line_height = 28,
    },
    caption = {
        size = 14,
        weight = "normal",
        line_height = 20,
    },
    label = {
        size = 16,
        weight = "normal",
        line_height = 22,
    },
}

-- State modifiers (for hover, pressed, disabled)
Tokens.STATES = {
    hover = {
        brightness = 0.1,    -- Lighten by 10%
    },
    pressed = {
        brightness = -0.1,   -- Darken by 10%
        offset_y = 2,        -- Visual "press down"
    },
    focused = {
        border_color = "accent",
        border_width = "heavy",
    },
    disabled = {
        opacity = 0.5,
        saturation = 0.3,
    },
}

-- Layout presets for common patterns
Tokens.LAYOUT = {
    -- Play mode split
    play = {
        left_percent = 0.55,
        right_percent = 0.45,
        status_bar_height = 48,
        panel_padding = 24,
        image_max_width = 2000,   -- Let panel size be the constraint
        image_max_height = 2000,  -- Let panel size be the constraint
        image_border = 4,
        button_width = 220,
        button_height = 64,
        button_gap = 24,
    },
    -- Config mode panels
    config = {
        top_bar_height = 60,
        status_bar_height = 40,
        pages_panel_width = 180,
        editor_panel_width = 500,
        preview_panel_width = 400,
        panel_padding = 16,
        preview_scale = 0.48,
    },
}

-- Utility function: lighten a color
function Tokens.lighten(color, amount)
    return {
        math.min(1, color[1] + amount),
        math.min(1, color[2] + amount),
        math.min(1, color[3] + amount),
        color[4] or 1
    }
end

-- Utility function: darken a color
function Tokens.darken(color, amount)
    return {
        math.max(0, color[1] - amount),
        math.max(0, color[2] - amount),
        math.max(0, color[3] - amount),
        color[4] or 1
    }
end

-- Utility function: set alpha on color
function Tokens.withAlpha(color, alpha)
    return {color[1], color[2], color[3], alpha}
end

return Tokens
