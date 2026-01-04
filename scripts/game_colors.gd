extends Node

# Cozy Dark Palette
const BACKGROUND = Color(0.12, 0.12, 0.15, 1.0)
const PANEL_BACKGROUND = Color(0.15, 0.15, 0.19, 1.0)
const PANEL_BORDER = Color(0.2, 0.2, 0.25, 1.0)

const BUTTON_NORMAL = Color(0.19, 0.19, 0.24, 1.0)
const BUTTON_HOVER = Color(0.24, 0.24, 0.3, 1.0)
const BUTTON_PRESSED = Color(0.14, 0.14, 0.18, 1.0)
const BUTTON_BORDER = Color(0.25, 0.25, 0.32, 1.0)
const BUTTON_BORDER_HOVER = Color(0.35, 0.35, 0.45, 1.0)

const ACCENT = Color(0.95, 0.65, 0.5, 1.0) # Amber
const TEXT = Color(0.9, 0.86, 0.8, 1.0)
const TEXT_MUTED = Color(0.5, 0.5, 0.5, 1.0)
const TEXT_HIGHLIGHT = Color(1.0, 1.0, 1.0, 1.0)

const HEALTH = Color(0.8, 0.4, 0.4, 1.0)
const SHIELD = Color(0.4, 0.6, 0.8, 1.0)
const PLAYER_HEALTH = Color(0.5, 0.7, 0.5, 1.0)

const ARENA_LINE = Color(0.3, 0.3, 0.4, 1.0)
const ARENA_LINE_SOFT = Color(0.4, 0.4, 0.5, 1.0)

const PROJECTILE_PLAYER = Color(0.9, 0.86, 0.8, 1.0)
const PROJECTILE_ENEMY = Color(0.4, 0.6, 0.8, 1.0)
const TRACER = Color(0.95, 0.75, 0.3, 1.0)
const ROCKET = Color(0.9, 0.4, 0.2, 1.0)

const ICE_PATCH = Color(0.4, 0.6, 0.8, 0.35)
const FROST_BOLT = Color(0.5, 0.7, 0.9, 1.0)

const HABBAKUK_BODY = Color(0.5, 0.6, 0.7, 1.0)
const HABBAKUK_BRIDGE = Color(0.3, 0.4, 0.5, 1.0)

const BOSS_DVD = Color(0.25, 0.25, 0.3, 1.0) # More distinct from BACKGROUND

func _ready() -> void:
	# Apply to the project theme at runtime
	var theme = ThemeDB.get_project_theme()
	if theme:
		_apply_to_theme(theme)

func _apply_to_theme(theme: Theme) -> void:
	# Button Colors
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT_HIGHLIGHT)
	theme.set_color("font_pressed_color", "Button", ACCENT)
	
	# Common Control colors
	theme.set_color("font_color", "Control", TEXT)
	theme.set_color("font_color_hover", "Control", TEXT_HIGHLIGHT)
	theme.set_color("font_color_pressed", "Control", ACCENT)
	
	# LineEdit
	theme.set_color("font_color", "LineEdit", TEXT)
	theme.set_color("selection_color", "LineEdit", ACCENT)
	
	# Styleboxes are harder to update generically because they are SubResources,
	# but we can update the colors of the ones we know exist.
	var types = ["Button", "Panel", "PanelContainer", "PopupPanel", "TabContainer"]
	var styles = ["normal", "hover", "pressed", "focus", "panel", "tab_selected", "tab_hovered", "tab_unselected"]
	
	for type in types:
		for style_name in styles:
			if theme.has_stylebox(style_name, type):
				var sb = theme.get_stylebox(style_name, type)
				if sb is StyleBoxFlat:
					_update_stylebox(sb, style_name)

func _update_stylebox(sb: StyleBoxFlat, style_name: String) -> void:
	match style_name:
		"normal", "panel":
			sb.bg_color = PANEL_BACKGROUND
			sb.border_color = PANEL_BORDER
		"hover", "tab_hovered":
			sb.bg_color = BUTTON_HOVER
			sb.border_color = BUTTON_BORDER_HOVER
		"pressed":
			sb.bg_color = BUTTON_PRESSED
			sb.border_color = BUTTON_BORDER
		"focus", "tab_selected":
			sb.border_color = ACCENT
		"tab_unselected":
			sb.bg_color = BACKGROUND
			sb.border_color = PANEL_BORDER

