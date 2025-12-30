extends Control

@export var toggle_action: String = "debug_toggle"
@export var enemy_group: String = "enemies"
@export var player_group: String = "player"
@export var arena_group: String = "arena"
@export var boss_config_path: String = "res://config/arenas/dvd_boss_arena.cfg"

var _bosses: Array = []
var _boss: Node = null
var _players: Array = []
var _player: Node = null
var _arenas: Array = []
var _arena: Node = null

var _boss_property_controls: Dictionary = {}
var _player_property_controls: Dictionary = {}
var _arena_property_controls: Dictionary = {}
var _suppress_sync: bool = false

@onready var _tab_container: TabContainer = get_node("Panel/Margin/VBox/TabContainer")
@onready
var _boss_status_label: Label = get_node("Panel/Margin/VBox/TabContainer/Boss/BossStatusLabel")
@onready var _boss_save_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Boss/BossButtons/BossSaveButton"
)
@onready var _boss_reset_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Boss/BossButtons/BossResetButton"
)
@onready
var _boss_rows: VBoxContainer = get_node("Panel/Margin/VBox/TabContainer/Boss/BossScroll/BossRows")

@onready var _player_status_label: Label = get_node(
	"Panel/Margin/VBox/TabContainer/Player/PlayerStatusLabel"
)
@onready var _player_save_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Player/PlayerButtons/PlayerSaveButton"
)
@onready var _player_reset_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Player/PlayerButtons/PlayerResetButton"
)
@onready var _player_rows: VBoxContainer = get_node(
	"Panel/Margin/VBox/TabContainer/Player/PlayerScroll/PlayerRows"
)

@onready
var _arena_status_label: Label = get_node("Panel/Margin/VBox/TabContainer/Arena/ArenaStatusLabel")
@onready var _arena_save_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Arena/ArenaButtons/ArenaSaveButton"
)
@onready var _arena_reset_button: Button = get_node(
	"Panel/Margin/VBox/TabContainer/Arena/ArenaButtons/ArenaResetButton"
)
@onready var _arena_rows: VBoxContainer = get_node(
	"Panel/Margin/VBox/TabContainer/Arena/ArenaScroll/ArenaRows"
)


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_boss_save_button.pressed.connect(_on_boss_save_pressed)
	_boss_reset_button.pressed.connect(_on_boss_reset_pressed)
	_player_save_button.pressed.connect(_on_player_save_pressed)
	_player_reset_button.pressed.connect(_on_player_reset_pressed)
	_arena_save_button.pressed.connect(_on_arena_save_pressed)
	_arena_reset_button.pressed.connect(_on_arena_reset_pressed)
	# Defer the initial refresh to ensure scene is fully ready
	call_deferred("_refresh_all")
	_update_cursor_state()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(toggle_action):
		visible = not visible
		if visible:
			_refresh_all()
			_pause_gameplay()
		else:
			_resume_gameplay()
		_update_cursor_state()
	if visible:
		if _bosses.is_empty():
			_refresh_boss()
		if _players.is_empty():
			_refresh_player()
		if _arenas.is_empty():
			_refresh_arena()


func _refresh_all() -> void:
	_refresh_boss()
	_refresh_player()
	_refresh_arena()


func _refresh_boss() -> void:
	_bosses = _find_bosses()
	_boss = _bosses[0] if not _bosses.is_empty() else null
	if _boss == null:
		_boss_status_label.text = "Boss: none"
		_clear_boss_controls()
		return
	_boss_status_label.text = "Bosses: %d" % _bosses.size()
	_apply_boss_saved_config()
	_build_boss_controls()


func _refresh_player() -> void:
	_players = _find_players()
	_player = _players[0] if not _players.is_empty() else null
	if _player == null:
		_player_status_label.text = "Player: none"
		_clear_player_controls()
		return
	_player_status_label.text = "Players: %d" % _players.size()
	_apply_player_saved_config()
	_build_player_controls()


func _refresh_arena() -> void:
	_arenas = _find_arenas()
	_arena = _arenas[0] if not _arenas.is_empty() else null
	if _arena == null:
		_arena_status_label.text = "Arena: none"
		_clear_arena_controls()
		return
	_arena_status_label.text = "Arenas: %d" % _arenas.size()
	_apply_arena_saved_config()
	_build_arena_controls()


func _find_bosses() -> Array:
	# Try multiple approaches to find boss nodes

	# Approach 1: Look in scene tree groups
	var bosses = get_tree().get_nodes_in_group(enemy_group)
	if not bosses.is_empty():
		return bosses

	# Approach 2: Look for nodes named "DVDBoss"
	var found = []
	_find_nodes_by_name(get_tree().get_root(), "DVDBoss", found)

	# Filter to only include nodes with the enemy group
	var valid_bosses = []
	for node in found:
		if node.is_in_group(enemy_group):
			valid_bosses.append(node)

	# If we found nodes but none are in the group, return them anyway
	# (the group might not be set up correctly)
	if not found.is_empty() and valid_bosses.is_empty():
		return found

	return valid_bosses


func _find_players() -> Array:
	# Try multiple approaches to find player nodes

	# Approach 1: Look in scene tree groups
	var players = get_tree().get_nodes_in_group(player_group)
	if not players.is_empty():
		return players

	# Approach 2: Look for nodes named "Player"
	var found = []
	_find_nodes_by_name(get_tree().get_root(), "Player", found)

	# Filter to only include nodes with the player group
	var valid_players = []
	for node in found:
		if node.is_in_group(player_group):
			valid_players.append(node)

	# If we found nodes but none are in the group, return them anyway
	# (the group might not be set up correctly)
	if not found.is_empty() and valid_players.is_empty():
		return found

	return valid_players


func _find_arenas() -> Array:
	# Try multiple approaches to find arena nodes

	# Approach 1: Look in scene tree groups
	var arenas = get_tree().get_nodes_in_group(arena_group)
	if not arenas.is_empty():
		return arenas

	# Approach 2: Look for nodes with bounds property (Rect2 type)
	# This finds any node that looks like it could be an arena
	var nodes_with_bounds = []
	_find_nodes_with_rect2_property(get_tree().get_root(), nodes_with_bounds)

	# Filter to only include nodes in the arena group OR named "Bounds"
	var valid_arenas = []
	for node in nodes_with_bounds:
		if node.is_in_group(arena_group) or node.name == "Bounds":
			valid_arenas.append(node)

	if not valid_arenas.is_empty():
		return valid_arenas

	# Approach 3: Look for nodes named "Bounds" specifically
	var bounds_nodes = []
	_find_nodes_by_name(get_tree().get_root(), "Bounds", bounds_nodes)

	# Check if any of these have the arena group
	for node in bounds_nodes:
		if node.is_in_group(arena_group):
			return [node]

	# If we found Bounds nodes but they're not in the group,
	# they might still be the arena (group might not be set up right)
	if not bounds_nodes.is_empty():
		return bounds_nodes

	# Approach 4: Look at parent hierarchy
	var parent = get_parent()
	while parent != null:
		if parent.name == "MainGame":
			# Found the main game node, look for Bounds child
			var bounds = parent.get_node_or_null("Bounds")
			if bounds != null:
				return [bounds]
			break
		parent = parent.get_parent()

	return []


func _find_nodes_with_rect2_property(root: Node, results: Array) -> void:
	if root == null:
		return

	# Check if this node has any Rect2 properties
	var props = root.get_property_list()
	for prop in props:
		if prop.get("type", TYPE_NIL) == TYPE_RECT2:
			# Check if it's a script variable (not built-in)
			var usage = prop.get("usage", 0)
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
				results.append(root)
				break

	# Recursively check children
	for child in root.get_children():
		_find_nodes_with_rect2_property(child, results)


func _find_nodes_by_name(root: Node, name_part: String, results: Array) -> void:
	if root == null:
		return
	if root.name.contains(name_part) or root.name == name_part:
		results.append(root)
	for child in root.get_children():
		_find_nodes_by_name(child, name_part, results)


func _clear_boss_controls() -> void:
	_boss_property_controls.clear()
	for child in _boss_rows.get_children():
		child.queue_free()


func _clear_player_controls() -> void:
	_player_property_controls.clear()
	for child in _player_rows.get_children():
		child.queue_free()


func _clear_arena_controls() -> void:
	_arena_property_controls.clear()
	for child in _arena_rows.get_children():
		child.queue_free()


func _build_boss_controls() -> void:
	_clear_boss_controls()
	if _boss == null:
		return
	_suppress_sync = true
	for prop in _boss.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		_create_boss_property_control(prop)
	_suppress_sync = false


func _build_player_controls() -> void:
	_clear_player_controls()
	if _player == null:
		return
	_suppress_sync = true
	for prop in _player.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		if prop.get("name", "") == "bounds":
			continue
		_create_player_property_control(prop)
	_suppress_sync = false


func _build_arena_controls() -> void:
	_clear_arena_controls()
	if _arena == null:
		return
	_suppress_sync = true
	for prop in _arena.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		_create_arena_property_control(prop)
	_suppress_sync = false


func _is_tweakable_property(prop: Dictionary) -> bool:
	var usage: int = prop.get("usage", 0)
	if (usage & PROPERTY_USAGE_EDITOR) == 0:
		return false
	if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
		return false
	var type: int = prop.get("type", TYPE_NIL)
	return type == TYPE_INT or type == TYPE_FLOAT or type == TYPE_RECT2


func _create_boss_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var type: int = prop.get("type", TYPE_NIL)

	if type == TYPE_RECT2:
		_create_rect2_property_control(prop, "boss")
		return

	var value: float = float(_boss.get(prop_name))
	var is_int: bool = type == TYPE_INT
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row_%s" % prop_name
	var label: Label = Label.new()
	label.text = prop_name
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_slider_range(slider, prop, value, "boss")
	slider.value = value
	row.add_child(slider)
	var value_line_edit: LineEdit = _create_value_line_edit(value, is_int, slider)
	row.add_child(value_line_edit)
	_boss_rows.add_child(row)
	_boss_property_controls[prop_name] = {
		"slider": slider,
		"label": value_line_edit,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_boss_slider_changed.bind(prop_name))


func _create_player_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var type: int = prop.get("type", TYPE_NIL)

	if type == TYPE_RECT2:
		_create_rect2_property_control(prop, "player")
		return

	var value: float = float(_player.get(prop_name))
	var is_int: bool = type == TYPE_INT
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row_%s" % prop_name
	var label: Label = Label.new()
	label.text = prop_name
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_slider_range(slider, prop, value, "player")
	slider.value = value
	row.add_child(slider)
	var value_line_edit: LineEdit = _create_value_line_edit(value, is_int, slider)
	row.add_child(value_line_edit)
	_player_rows.add_child(row)
	_player_property_controls[prop_name] = {
		"slider": slider,
		"label": value_line_edit,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_player_slider_changed.bind(prop_name))


func _create_rect2_property_control(prop: Dictionary, target_type: String) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return

	var rect_value: Rect2
	if target_type == "arena":
		if _arena == null:
			return
		rect_value = _arena.get(prop_name)
	elif target_type == "boss":
		if _boss == null:
			return
		rect_value = _boss.get(prop_name)
	elif target_type == "player":
		if _player == null:
			return
		rect_value = _player.get(prop_name)
	else:
		return

	# Handle null or invalid rect
	if typeof(rect_value) != TYPE_RECT2:
		return

	# Create a container for the Rect2 controls
	var container: VBoxContainer = VBoxContainer.new()
	container.name = "Row_%s" % prop_name

	# Create label for property name
	var header_label: Label = Label.new()
	header_label.text = prop_name
	header_label.custom_minimum_size = Vector2(140, 0)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	container.add_child(header_label)

	# Create controls for each component.
	var components = []
	if target_type == "arena" and prop_name == "bounds":
		components = [
			{"name": "width", "value": rect_value.size.x},
			{"name": "height", "value": rect_value.size.y}
		]
	else:
		components = [
			{"name": "x", "value": rect_value.position.x},
			{"name": "y", "value": rect_value.position.y},
			{"name": "width", "value": rect_value.size.x},
			{"name": "height", "value": rect_value.size.y}
		]

	for comp in components:
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "Row_%s_%s" % [prop_name, comp.name]

		var comp_label: Label = Label.new()
		comp_label.text = "  %s" % comp.name
		comp_label.custom_minimum_size = Vector2(130, 0)
		row.add_child(comp_label)

		var slider: HSlider = HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = 0.0
		slider.max_value = max(1.0, abs(comp.value) * 3.0)
		slider.step = 1.0
		slider.value = comp.value
		row.add_child(slider)

		var value_line_edit: LineEdit = _create_value_line_edit(comp.value, true, slider)
		row.add_child(value_line_edit)

		container.add_child(row)

		# Store control info
		var control_key = "%s_%s" % [prop_name, comp.name]
		if target_type == "arena":
			_arena_property_controls[control_key] = {
				"slider": slider, "label": value_line_edit, "is_int": true, "component": comp.name
			}
			slider.value_changed.connect(_on_arena_rect2_slider_changed.bind(prop_name, comp.name))
		elif target_type == "boss":
			_boss_property_controls[control_key] = {
				"slider": slider, "label": value_line_edit, "is_int": true, "component": comp.name
			}
			slider.value_changed.connect(_on_boss_rect2_slider_changed.bind(prop_name, comp.name))
		elif target_type == "player":
			_player_property_controls[control_key] = {
				"slider": slider, "label": value_line_edit, "is_int": true, "component": comp.name
			}
			slider.value_changed.connect(_on_player_rect2_slider_changed.bind(prop_name, comp.name))

	if target_type == "arena":
		_arena_rows.add_child(container)
	elif target_type == "boss":
		_boss_rows.add_child(container)
	elif target_type == "player":
		_player_rows.add_child(container)


func _create_arena_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var type: int = prop.get("type", TYPE_NIL)

	if type == TYPE_RECT2:
		_create_rect2_property_control(prop, "arena")
		return

	var value: float = float(_arena.get(prop_name))
	var is_int: bool = type == TYPE_INT
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row_%s" % prop_name
	var label: Label = Label.new()
	label.text = prop_name
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_slider_range(slider, prop, value, "arena")
	slider.value = value
	row.add_child(slider)
	var value_line_edit: LineEdit = _create_value_line_edit(value, is_int, slider)
	row.add_child(value_line_edit)
	_arena_rows.add_child(row)
	_arena_property_controls[prop_name] = {
		"slider": slider,
		"label": value_line_edit,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_arena_slider_changed.bind(prop_name))


func _apply_slider_range(
	slider: HSlider, prop: Dictionary, value: float, target_type: String
) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "current_health" or prop_name == "current_shield":
		slider.min_value = 0.0
		var max_val := 1.0
		if target_type == "boss":
			if prop_name == "current_health":
				max_val = _get_max_boss_health()
			else:
				max_val = _get_max_boss_shield()
		elif target_type == "player":
			max_val = _get_max_player_health()
		slider.max_value = max(1.0, max_val)
		slider.step = 1.0
		return

	var hint: int = prop.get("hint", PROPERTY_HINT_NONE)
	var hint_string: String = prop.get("hint_string", "")
	if hint == PROPERTY_HINT_RANGE and hint_string != "":
		var parts: PackedStringArray = hint_string.split(",", false)
		if parts.size() >= 2:
			slider.min_value = float(parts[0])
			slider.max_value = float(parts[1])
			if parts.size() >= 3:
				slider.step = float(parts[2])
			else:
				slider.step = _default_step(prop)
			return

	var magnitude: float = abs(value)
	if value < 0.0:
		slider.min_value = value * 2.0
		slider.max_value = max(1.0, magnitude * 3.0)
	else:
		slider.min_value = 0.0
		slider.max_value = max(1.0, magnitude * 3.0)
	slider.step = _default_step(prop)


func _default_step(prop: Dictionary) -> float:
	return 1.0 if prop.get("type", TYPE_FLOAT) == TYPE_INT else 0.01


func _on_boss_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _bosses.is_empty():
		return
	if not _boss_property_controls.has(prop_name):
		return
	var info: Dictionary = _boss_property_controls[prop_name]
	var is_int: bool = info.get("is_int", false)
	var line_edit: LineEdit = info.get("label") as LineEdit
	if is_int:
		var new_value_int: int = int(round(value))
		for boss in _bosses:
			if not is_instance_valid(boss):
				continue
			boss.set(prop_name, new_value_int)
			if prop_name == "speed":
				_update_boss_speed(boss, float(new_value_int))
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(float(new_value_int), true)
	else:
		for boss in _bosses:
			if not is_instance_valid(boss):
				continue
			boss.set(prop_name, value)
			if prop_name == "speed":
				_update_boss_speed(boss, value)
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(value, false)
	if prop_name == "max_health" and _boss_property_controls.has("current_health"):
		_update_boss_current_health_control()
	if prop_name == "max_shield" and _boss_property_controls.has("current_shield"):
		_update_boss_current_shield_control()
	_refresh_boss_visuals()


func _on_player_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _players.is_empty():
		return
	if not _player_property_controls.has(prop_name):
		return
	var info: Dictionary = _player_property_controls[prop_name]
	var is_int: bool = info.get("is_int", false)
	var line_edit: LineEdit = info.get("label") as LineEdit
	if is_int:
		var new_value_int: int = int(round(value))
		for player in _players:
			if not is_instance_valid(player):
				continue
			player.set(prop_name, new_value_int)
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(float(new_value_int), true)
	else:
		for player in _players:
			if not is_instance_valid(player):
				continue
			player.set(prop_name, value)
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(value, false)
	if prop_name == "max_health" and _player_property_controls.has("current_health"):
		_update_player_current_health_control()


func _on_arena_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _arenas.is_empty():
		return
	if not _arena_property_controls.has(prop_name):
		return
	var info: Dictionary = _arena_property_controls[prop_name]
	var is_int: bool = info.get("is_int", false)
	var line_edit: LineEdit = info.get("label") as LineEdit
	if is_int:
		var new_value_int: int = int(round(value))
		for arena in _arenas:
			if not is_instance_valid(arena):
				continue
			arena.set(prop_name, new_value_int)
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(float(new_value_int), true)
	else:
		for arena in _arenas:
			if not is_instance_valid(arena):
				continue
			arena.set(prop_name, value)
		if line_edit != null and not line_edit.has_focus():
			line_edit.text = _format_value(value, false)
	_refresh_arena_visuals()


func _on_arena_rect2_slider_changed(value: float, prop_name: String, component: String) -> void:
	if _suppress_sync or _arenas.is_empty():
		return

	var control_key = "%s_%s" % [prop_name, component]
	if not _arena_property_controls.has(control_key):
		return

	var info: Dictionary = _arena_property_controls[control_key]
	var line_edit: LineEdit = info.get("label") as LineEdit
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(value, true)

	# Update all arenas with the new Rect2 value
	for arena in _arenas:
		if not is_instance_valid(arena):
			continue

		var current_rect: Rect2 = arena.get(prop_name)
		var new_rect: Rect2 = current_rect

		match component:
			"x":
				new_rect.position.x = int(round(value))
			"y":
				new_rect.position.y = int(round(value))
			"width":
				new_rect.size.x = int(round(value))
			"height":
				new_rect.size.y = int(round(value))
		if prop_name == "bounds":
			new_rect.position = -new_rect.size * 0.5
		arena.set(prop_name, new_rect)

	_refresh_arena_visuals()


func _on_boss_rect2_slider_changed(value: float, prop_name: String, component: String) -> void:
	if _suppress_sync or _bosses.is_empty():
		return

	var control_key = "%s_%s" % [prop_name, component]
	if not _boss_property_controls.has(control_key):
		return

	var info: Dictionary = _boss_property_controls[control_key]
	var line_edit: LineEdit = info.get("label") as LineEdit
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(value, true)

	# Update all bosses with the new Rect2 value
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue

		var current_rect: Rect2 = boss.get(prop_name)
		var new_rect: Rect2 = current_rect

		match component:
			"x":
				new_rect.position.x = int(round(value))
			"y":
				new_rect.position.y = int(round(value))
			"width":
				new_rect.size.x = int(round(value))
			"height":
				new_rect.size.y = int(round(value))

		boss.set(prop_name, new_rect)

	_refresh_boss_visuals()


func _on_player_rect2_slider_changed(value: float, prop_name: String, component: String) -> void:
	if _suppress_sync or _players.is_empty():
		return

	var control_key = "%s_%s" % [prop_name, component]
	if not _player_property_controls.has(control_key):
		return

	var info: Dictionary = _player_property_controls[control_key]
	var line_edit: LineEdit = info.get("label") as LineEdit
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(value, true)

	# Update all players with the new Rect2 value
	for player in _players:
		if not is_instance_valid(player):
			continue

		var current_rect: Rect2 = player.get(prop_name)
		var new_rect: Rect2 = current_rect

		match component:
			"x":
				new_rect.position.x = int(round(value))
			"y":
				new_rect.position.y = int(round(value))
			"width":
				new_rect.size.x = int(round(value))
			"height":
				new_rect.size.y = int(round(value))

		player.set(prop_name, new_rect)


func _update_boss_current_health_control() -> void:
	var info: Dictionary = _boss_property_controls.get("current_health", {})
	var slider: HSlider = info.get("slider") as HSlider
	var line_edit: LineEdit = info.get("label") as LineEdit
	if slider == null or _bosses.is_empty():
		return
	var max_health := _get_max_boss_health()
	slider.max_value = max(1.0, max_health)
	var clamped: float = clamp(float(slider.value), 0.0, max_health)
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		boss.current_health = clamp(clamped, 0.0, float(boss.max_health))
	slider.value = clamped
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(clamped, true)


func _update_boss_current_shield_control() -> void:
	var info: Dictionary = _boss_property_controls.get("current_shield", {})
	var slider: HSlider = info.get("slider") as HSlider
	var line_edit: LineEdit = info.get("label") as LineEdit
	if slider == null or _bosses.is_empty():
		return
	var max_shield := _get_max_boss_shield()
	slider.max_value = max(1.0, max_shield)
	var clamped: float = clamp(float(slider.value), 0.0, max_shield)
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		boss.current_shield = clamp(clamped, 0.0, float(boss.max_shield))
	slider.value = clamped
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(clamped, true)


func _update_player_current_health_control() -> void:
	var info: Dictionary = _player_property_controls.get("current_health", {})
	var slider: HSlider = info.get("slider") as HSlider
	var line_edit: LineEdit = info.get("label") as LineEdit
	if slider == null or _players.is_empty():
		return
	var max_health := _get_max_player_health()
	slider.max_value = max(1.0, max_health)
	var clamped: float = clamp(float(slider.value), 0.0, max_health)
	for player in _players:
		if not is_instance_valid(player):
			continue
		player.current_health = clamp(clamped, 0.0, float(player.max_health))
	slider.value = clamped
	if line_edit != null and not line_edit.has_focus():
		line_edit.text = _format_value(clamped, true)


func _refresh_boss_visuals() -> void:
	if _bosses.is_empty():
		return
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		if boss.has_method("_apply_visuals"):
			boss.call("_apply_visuals")
		if boss.has_method("_update_health_bar"):
			boss.call("_update_health_bar")
		if boss.has_method("_sync_boss_bar"):
			boss.call("_sync_boss_bar")


func _refresh_arena_visuals() -> void:
	if _arenas.is_empty():
		return
	for arena in _arenas:
		if not is_instance_valid(arena):
			continue
		if arena.has_method("queue_redraw"):
			arena.call("queue_redraw")

	# Update player bounds since it caches the arena bounds
	# (DVD Boss already fetches fresh bounds each frame via _get_world_bounds())
	if not _players.is_empty():
		for player in _players:
			if not is_instance_valid(player):
				continue
			# Check if player has bounds_node and bounds property
			if player.has_method("get") and player.has_method("set"):
				var bounds_node_path = player.get("bounds_node")
				if bounds_node_path != null and bounds_node_path != NodePath():
					var bounds_node = get_node_or_null(bounds_node_path)
					if bounds_node != null and bounds_node.has_method("get_bounds"):
						var arena_bounds = bounds_node.get_bounds()
						if player.has_property("bounds"):
							player.bounds = arena_bounds


func _format_value(value: float, is_int: bool) -> String:
	return String.num(value, 0 if is_int else 2)


func _pause_gameplay() -> void:
	# Pause all gameplay nodes but keep UI nodes active
	for node in get_tree().get_root().get_children():
		if node is CanvasLayer:
			# Skip the debug menu layer itself
			if node.name == "DebugMenuLayer":
				continue
			# Set process mode for UI layers to PAUSABLE so they still work
			node.process_mode = Node.PROCESS_MODE_PAUSABLE
		elif node is Node2D:
			# Pause gameplay nodes
			node.process_mode = Node.PROCESS_MODE_DISABLED
		elif node is Node:
			# Check if it's a gameplay-related node
			if (
				node.name
				in [
					"Player",
					"DVDBoss",
					"Projectiles",
					"BossHealthBar",
					"PlayerHealthBar",
					"Bounds",
					"Camera2D"
				]
			):
				node.process_mode = Node.PROCESS_MODE_DISABLED
			# Keep pause menu controller active
			elif node.name == "PauseMenuController":
				node.process_mode = Node.PROCESS_MODE_PAUSABLE
			# Keep game over window active
			elif node.name == "GameOverWindow":
				node.process_mode = Node.PROCESS_MODE_PAUSABLE


func _resume_gameplay() -> void:
	# Resume all nodes
	for node in get_tree().get_root().get_children():
		node.process_mode = Node.PROCESS_MODE_INHERIT


func _update_cursor_state() -> void:
	_set_crosshair_enabled(not visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_HIDDEN


func _set_crosshair_enabled(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("crosshair_cursor"):
		if node.has_method("set_enabled"):
			node.call("set_enabled", enabled)
		else:
			node.visible = enabled


func _get_max_boss_health() -> float:
	var max_value := 1.0
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		max_value = max(max_value, float(boss.max_health))
	return max_value


func _get_max_boss_shield() -> float:
	var max_value := 1.0
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		max_value = max(max_value, float(boss.max_shield))
	return max_value


func _get_max_player_health() -> float:
	var max_value := 1.0
	for player in _players:
		if not is_instance_valid(player):
			continue
		max_value = max(max_value, float(player.max_health))
	return max_value


func _update_boss_speed(boss: Node, new_speed: float) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var velocity_value: Variant = boss.get("_velocity")
	if velocity_value is Vector2:
		var direction: Vector2 = velocity_value
		if direction.length_squared() <= 0.0001:
			direction = Vector2.RIGHT
		boss.set("speed", new_speed)
		boss.call("set_velocity", direction.normalized() * new_speed)


func _on_boss_save_pressed() -> void:
	if _boss == null:
		return
	var data := _collect_boss_values(_boss)
	_write_boss_config(data)


func _on_boss_reset_pressed() -> void:
	_on_boss_save_pressed()
	_resume_gameplay()
	get_tree().reload_current_scene()


func _on_player_save_pressed() -> void:
	if _player == null:
		return
	var data := _collect_player_values(_player)
	_write_player_config(data)


func _on_player_reset_pressed() -> void:
	_on_player_save_pressed()
	_resume_gameplay()
	get_tree().reload_current_scene()


func _on_arena_save_pressed() -> void:
	if _arena == null:
		return
	var data := _collect_arena_values(_arena)
	_write_arena_config(data)


func _on_arena_reset_pressed() -> void:
	_on_arena_save_pressed()
	_resume_gameplay()
	get_tree().reload_current_scene()


func _apply_boss_saved_config() -> void:
	var data := _read_boss_config()
	if data.is_empty():
		return
	for boss in _bosses:
		if not is_instance_valid(boss):
			continue
		for key in data.keys():
			if not boss.has_method("set"):
				continue
			if boss.get(key) == null:
				continue
			var value = data[key]
			# Handle Rect2 stored as dictionary
			if (
				value is Dictionary
				and value.has("x")
				and value.has("y")
				and value.has("width")
				and value.has("height")
			):
				var rect_value = Rect2(
					float(value["x"]),
					float(value["y"]),
					float(value["width"]),
					float(value["height"])
				)
				boss.set(key, rect_value)
			else:
				boss.set(key, value)
				if key == "speed":
					_update_boss_speed(boss, float(data[key]))


func _apply_player_saved_config() -> void:
	var data := _read_player_config()
	if data.is_empty():
		return
	for player in _players:
		if not is_instance_valid(player):
			continue
		for key in data.keys():
			if not player.has_method("set"):
				continue
			if player.get(key) == null:
				continue
			var value = data[key]
			# Handle Rect2 stored as dictionary
			if (
				value is Dictionary
				and value.has("x")
				and value.has("y")
				and value.has("width")
				and value.has("height")
			):
				var rect_value = Rect2(
					float(value["x"]),
					float(value["y"]),
					float(value["width"]),
					float(value["height"])
				)
				player.set(key, rect_value)
			else:
				player.set(key, data[key])


func _apply_arena_saved_config() -> void:
	var data := _read_arena_config()
	if data.is_empty():
		return
	for arena in _arenas:
		if not is_instance_valid(arena):
			continue
		for key in data.keys():
			if not arena.has_method("set"):
				continue
			if arena.get(key) == null:
				continue
			var value = data[key]
			# Handle Rect2 stored as dictionary
			if (
				value is Dictionary
				and value.has("x")
				and value.has("y")
				and value.has("width")
				and value.has("height")
			):
				var rect_value = Rect2(
					float(value["x"]),
					float(value["y"]),
					float(value["width"]),
					float(value["height"])
				)
				arena.set(key, rect_value)
			else:
				arena.set(key, value)


func _collect_boss_values(boss: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in boss.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "" or prop_name.begins_with("current_"):
			continue
		var type: int = prop.get("type", TYPE_NIL)
		if type == TYPE_RECT2:
			# Store Rect2 as a dictionary with components
			var rect_value: Rect2 = boss.get(prop_name)
			values[prop_name] = {
				"x": rect_value.position.x,
				"y": rect_value.position.y,
				"width": rect_value.size.x,
				"height": rect_value.size.y
			}
		else:
			values[prop_name] = boss.get(prop_name)
	return values


func _collect_player_values(player: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in player.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "" or prop_name.begins_with("current_"):
			continue
		var type: int = prop.get("type", TYPE_NIL)
		if type == TYPE_RECT2:
			# Store Rect2 as a dictionary with components
			var rect_value: Rect2 = player.get(prop_name)
			values[prop_name] = {
				"x": rect_value.position.x,
				"y": rect_value.position.y,
				"width": rect_value.size.x,
				"height": rect_value.size.y
			}
		else:
			values[prop_name] = player.get(prop_name)
	return values


func _collect_arena_values(arena: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in arena.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "" or prop_name.begins_with("current_"):
			continue
		var type: int = prop.get("type", TYPE_NIL)
		if type == TYPE_RECT2:
			# Store Rect2 as a dictionary with components
			var rect_value: Rect2 = arena.get(prop_name)
			values[prop_name] = {
				"x": rect_value.position.x,
				"y": rect_value.position.y,
				"width": rect_value.size.x,
				"height": rect_value.size.y
			}
		else:
			values[prop_name] = arena.get(prop_name)
	return values


func _write_boss_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	var load_err := config.load(boss_config_path)
	if load_err != OK:
		push_warning("Failed to load existing boss config, creating new one")
	for key in values.keys():
		config.set_value("boss", key, values[key])
	var err := config.save(boss_config_path)
	if err != OK:
		push_warning("Failed to write boss config to: " + boss_config_path)
	else:
		print("Boss config saved to: " + boss_config_path)


func _write_player_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("player", key, values[key])
	var err := config.save("user://player_config.cfg")
	if err != OK:
		push_warning("Failed to write player config")


func _write_arena_config(values: Dictionary) -> void:
	# Save to the actual arena config file
	var arena_config_path := "res://config/arenas/dvd_boss_arena.cfg"
	var config := ConfigFile.new()

	# Load existing config to preserve other sections
	var load_err := config.load(arena_config_path)
	if load_err != OK:
		push_warning("Failed to load existing arena config, creating new one")

	# Update arena section with bounds
	if values.has("bounds"):
		var bounds_data = values["bounds"]
		if bounds_data is Dictionary:
			var rect := Rect2(
				float(bounds_data["x"]),
				float(bounds_data["y"]),
				float(bounds_data["width"]),
				float(bounds_data["height"])
			)
			config.set_value("arena", "bounds", rect)

	# Save other arena values
	for key in values.keys():
		if key == "bounds":
			continue  # Already handled above
		config.set_value("arena", key, values[key])

	var err := config.save(arena_config_path)
	if err != OK:
		push_warning("Failed to write arena config to: " + arena_config_path)
	else:
		print("Arena config saved to: " + arena_config_path)


func _read_boss_config() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(boss_config_path)
	if err != OK:
		err = config.load("user://boss_config.cfg")
		if err != OK:
			return {}
	if not config.has_section("boss"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("boss"):
		var value = config.get_value("boss", key)
		if value is Rect2:
			result[key] = {
				"x": value.position.x,
				"y": value.position.y,
				"width": value.size.x,
				"height": value.size.y
			}
		else:
			result[key] = value
	return result


func _read_player_config() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load("user://player_config.cfg")
	if err != OK:
		return {}
	if not config.has_section("player"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("player"):
		result[key] = config.get_value("player", key)
	return result


func _read_arena_config() -> Dictionary:
	# Read from the actual arena config file
	var arena_config_path := "res://config/arenas/dvd_boss_arena.cfg"
	var config := ConfigFile.new()
	var err := config.load(arena_config_path)
	if err != OK:
		return {}
	if not config.has_section("arena"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("arena"):
		var value = config.get_value("arena", key)
		# Convert Rect2 to dictionary format for consistency
		if value is Rect2:
			result[key] = {
				"x": value.position.x,
				"y": value.position.y,
				"width": value.size.x,
				"height": value.size.y
			}
		else:
			result[key] = value
	return result


func _create_value_line_edit(value: float, is_int: bool, slider: HSlider) -> LineEdit:
	var line_edit := LineEdit.new()
	line_edit.custom_minimum_size = Vector2(72, 0)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line_edit.text = _format_value(value, is_int)
	line_edit.select_all_on_focus = true

	line_edit.text_submitted.connect(_on_value_edit_submitted.bind(slider, is_int, line_edit))
	line_edit.focus_exited.connect(_on_value_focus_exited.bind(line_edit, slider, is_int))

	return line_edit


func _on_value_edit_submitted(
	new_text: String, slider: HSlider, is_int: bool, line_edit: LineEdit
) -> void:
	_apply_text_value(new_text, slider, is_int, line_edit)
	line_edit.release_focus()


func _on_value_focus_exited(line_edit: LineEdit, slider: HSlider, is_int: bool) -> void:
	_apply_text_value(line_edit.text, slider, is_int, line_edit)


func _apply_text_value(text: String, slider: HSlider, is_int: bool, line_edit: LineEdit) -> void:
	if not text.is_valid_float():
		line_edit.text = _format_value(slider.value, is_int)
		return

	var new_val := float(text)
	if is_int:
		new_val = round(new_val)

	if new_val < slider.min_value:
		slider.min_value = new_val
	if new_val > slider.max_value:
		slider.max_value = new_val

	if not is_equal_approx(slider.value, new_val):
		slider.value = new_val
	else:
		# If value is same, format the text just in case (e.g. "5.00" -> "5")
		line_edit.text = _format_value(slider.value, is_int)
