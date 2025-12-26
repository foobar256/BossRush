extends Control

@export var toggle_action: String = "debug_player_toggle"
@export var player_group: String = "player"
@export var config_path: String = "user://player_config.cfg"

var _players: Array = []
var _player: Node = null
var _property_controls: Dictionary = {}
var _suppress_sync: bool = false

@onready var _status_label: Label = get_node("Panel/Margin/VBox/StatusLabel")
@onready var _save_button: Button = get_node("Panel/Margin/VBox/Buttons/SaveButton")
@onready var _reset_button: Button = get_node("Panel/Margin/VBox/Buttons/ResetButton")
@onready var _rows: VBoxContainer = get_node("Panel/Margin/VBox/Scroll/Rows")


func _ready() -> void:
	add_to_group("debug_menu")
	visible = false
	_save_button.pressed.connect(_on_save_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
	_refresh_player()
	_update_cursor_state()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(toggle_action):
		visible = not visible
		if visible:
			_refresh_player()
		_update_cursor_state()
	if visible and _players.is_empty():
		_refresh_player()


func _refresh_player() -> void:
	_players = _find_players()
	_player = _players[0] if not _players.is_empty() else null
	if _player == null:
		_status_label.text = "Player: none"
		_clear_controls()
		return
	_status_label.text = "Players: %d" % _players.size()
	_apply_saved_config()
	_build_controls()


func _find_players() -> Array:
	return get_tree().get_nodes_in_group(player_group)


func _clear_controls() -> void:
	_property_controls.clear()
	for child in _rows.get_children():
		child.queue_free()


func _build_controls() -> void:
	_clear_controls()
	if _player == null:
		return
	_suppress_sync = true
	for prop in _player.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		_create_property_control(prop)
	_suppress_sync = false


func _is_tweakable_property(prop: Dictionary) -> bool:
	var usage: int = prop.get("usage", 0)
	if (usage & PROPERTY_USAGE_EDITOR) == 0:
		return false
	if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
		return false
	var type: int = prop.get("type", TYPE_NIL)
	return type == TYPE_INT or type == TYPE_FLOAT


func _create_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var value: float = float(_player.get(prop_name))
	var is_int: bool = prop.get("type", TYPE_FLOAT) == TYPE_INT
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "Row_%s" % prop_name
	var label: Label = Label.new()
	label.text = prop_name
	label.custom_minimum_size = Vector2(140, 0)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_slider_range(slider, prop, value)
	slider.value = value
	row.add_child(slider)
	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_value(value, is_int)
	row.add_child(value_label)
	_rows.add_child(row)
	_property_controls[prop_name] = {
		"slider": slider,
		"label": value_label,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_slider_changed.bind(prop_name))


func _apply_slider_range(slider: HSlider, prop: Dictionary, value: float) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "current_health":
		slider.min_value = 0.0
		slider.max_value = max(1.0, _get_max_player_health())
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


func _on_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _players.is_empty():
		return
	if not _property_controls.has(prop_name):
		return
	var info: Dictionary = _property_controls[prop_name]
	var is_int: bool = info.get("is_int", false)
	var label: Label = info.get("label") as Label
	if is_int:
		var new_value_int: int = int(round(value))
		for player in _players:
			if not is_instance_valid(player):
				continue
			player.set(prop_name, new_value_int)
		if label != null:
			label.text = _format_value(float(new_value_int), true)
	else:
		for player in _players:
			if not is_instance_valid(player):
				continue
			player.set(prop_name, value)
		if label != null:
			label.text = _format_value(value, false)
	if prop_name == "max_health" and _property_controls.has("current_health"):
		_update_current_health_control()


func _update_current_health_control() -> void:
	var info: Dictionary = _property_controls.get("current_health", {})
	var slider: HSlider = info.get("slider") as HSlider
	var label: Label = info.get("label") as Label
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
	if label != null:
		label.text = _format_value(clamped, true)


func _format_value(value: float, is_int: bool) -> String:
	return String.num(value, 0 if is_int else 2)


func _update_cursor_state() -> void:
	var any_visible := _any_debug_menu_visible()
	_set_crosshair_enabled(not any_visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if any_visible else Input.MOUSE_MODE_HIDDEN


func _set_crosshair_enabled(enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group("crosshair_cursor"):
		if node.has_method("set_enabled"):
			node.call("set_enabled", enabled)
		else:
			node.visible = enabled


func _any_debug_menu_visible() -> bool:
	for menu in get_tree().get_nodes_in_group("debug_menu"):
		if menu.visible:
			return true
	return false


func _get_max_player_health() -> float:
	var max_value := 1.0
	for player in _players:
		if not is_instance_valid(player):
			continue
		max_value = max(max_value, float(player.max_health))
	return max_value


func _on_save_pressed() -> void:
	if _player == null:
		return
	var data := _collect_player_values(_player)
	_write_config(data)


func _on_reset_pressed() -> void:
	_on_save_pressed()
	get_tree().reload_current_scene()


func _apply_saved_config() -> void:
	var data := _read_config()
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
			player.set(key, data[key])


func _collect_player_values(player: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in player.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "":
			continue
		values[prop_name] = player.get(prop_name)
	return values


func _write_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("player", key, values[key])
	var err := config.save(config_path)
	if err != OK:
		push_warning("Failed to write player config: %s" % config_path)


func _read_config() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load(config_path)
	if err != OK:
		return {}
	if not config.has_section("player"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("player"):
		result[key] = config.get_value("player", key)
	return result
