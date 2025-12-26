extends Control

@export var toggle_action: String = "debug_toggle"
@export var enemy_group: String = "enemies"
@export var player_group: String = "player"
@export var arena_group: String = "arena"

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
@onready var _boss_status_label: Label = get_node("Panel/Margin/VBox/TabContainer/Boss/BossStatusLabel")
@onready var _boss_save_button: Button = get_node("Panel/Margin/VBox/TabContainer/Boss/BossButtons/BossSaveButton")
@onready var _boss_reset_button: Button = get_node("Panel/Margin/VBox/TabContainer/Boss/BossButtons/BossResetButton")
@onready var _boss_rows: VBoxContainer = get_node("Panel/Margin/VBox/TabContainer/Boss/BossScroll/BossRows")

@onready var _player_status_label: Label = get_node("Panel/Margin/VBox/TabContainer/Player/PlayerStatusLabel")
@onready var _player_save_button: Button = get_node("Panel/Margin/VBox/TabContainer/Player/PlayerButtons/PlayerSaveButton")
@onready var _player_reset_button: Button = get_node("Panel/Margin/VBox/TabContainer/Player/PlayerButtons/PlayerResetButton")
@onready var _player_rows: VBoxContainer = get_node("Panel/Margin/VBox/TabContainer/Player/PlayerScroll/PlayerRows")

@onready var _arena_status_label: Label = get_node("Panel/Margin/VBox/TabContainer/Arena/ArenaStatusLabel")
@onready var _arena_save_button: Button = get_node("Panel/Margin/VBox/TabContainer/Arena/ArenaButtons/ArenaSaveButton")
@onready var _arena_reset_button: Button = get_node("Panel/Margin/VBox/TabContainer/Arena/ArenaButtons/ArenaResetButton")
@onready var _arena_rows: VBoxContainer = get_node("Panel/Margin/VBox/TabContainer/Arena/ArenaScroll/ArenaRows")


func _ready() -> void:
	visible = false
	_boss_save_button.pressed.connect(_on_boss_save_pressed)
	_boss_reset_button.pressed.connect(_on_boss_reset_pressed)
	_player_save_button.pressed.connect(_on_player_save_pressed)
	_player_reset_button.pressed.connect(_on_player_reset_pressed)
	_arena_save_button.pressed.connect(_on_arena_save_pressed)
	_arena_reset_button.pressed.connect(_on_arena_reset_pressed)
	_refresh_all()
	_update_cursor_state()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(toggle_action):
		visible = not visible
		if visible:
			_refresh_all()
			get_tree().paused = true
		else:
			get_tree().paused = false
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
	return get_tree().get_nodes_in_group(enemy_group)


func _find_players() -> Array:
	return get_tree().get_nodes_in_group(player_group)


func _find_arenas() -> Array:
	return get_tree().get_nodes_in_group(arena_group)


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
	return type == TYPE_INT or type == TYPE_FLOAT


func _create_boss_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var value: float = float(_boss.get(prop_name))
	var is_int: bool = prop.get("type", TYPE_FLOAT) == TYPE_INT
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
	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_value(value, is_int)
	row.add_child(value_label)
	_boss_rows.add_child(row)
	_boss_property_controls[prop_name] = {
		"slider": slider,
		"label": value_label,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_boss_slider_changed.bind(prop_name))


func _create_player_property_control(prop: Dictionary) -> void:
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
	_apply_slider_range(slider, prop, value, "player")
	slider.value = value
	row.add_child(slider)
	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_value(value, is_int)
	row.add_child(value_label)
	_player_rows.add_child(row)
	_player_property_controls[prop_name] = {
		"slider": slider,
		"label": value_label,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_player_slider_changed.bind(prop_name))


func _create_arena_property_control(prop: Dictionary) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "":
		return
	var value: float = float(_arena.get(prop_name))
	var is_int: bool = prop.get("type", TYPE_FLOAT) == TYPE_INT
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
	var value_label: Label = Label.new()
	value_label.custom_minimum_size = Vector2(72, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_value(value, is_int)
	row.add_child(value_label)
	_arena_rows.add_child(row)
	_arena_property_controls[prop_name] = {
		"slider": slider,
		"label": value_label,
		"is_int": is_int,
	}
	slider.value_changed.connect(_on_arena_slider_changed.bind(prop_name))


func _apply_slider_range(slider: HSlider, prop: Dictionary, value: float, target_type: String) -> void:
	var prop_name: String = prop.get("name", "")
	if prop_name == "current_health":
		slider.min_value = 0.0
		var max_health := 1.0
		if target_type == "boss":
			max_health = _get_max_boss_health()
		elif target_type == "player":
			max_health = _get_max_player_health()
		slider.max_value = max(1.0, max_health)
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
	var label: Label = info.get("label") as Label
	if is_int:
		var new_value_int: int = int(round(value))
		for boss in _bosses:
			if not is_instance_valid(boss):
				continue
			boss.set(prop_name, new_value_int)
			if prop_name == "speed":
				_update_boss_speed(boss, float(new_value_int))
		if label != null:
			label.text = _format_value(float(new_value_int), true)
	else:
		for boss in _bosses:
			if not is_instance_valid(boss):
				continue
			boss.set(prop_name, value)
			if prop_name == "speed":
				_update_boss_speed(boss, value)
		if label != null:
			label.text = _format_value(value, false)
	if prop_name == "max_health" and _boss_property_controls.has("current_health"):
		_update_boss_current_health_control()
	_refresh_boss_visuals()


func _on_player_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _players.is_empty():
		return
	if not _player_property_controls.has(prop_name):
		return
	var info: Dictionary = _player_property_controls[prop_name]
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
	if prop_name == "max_health" and _player_property_controls.has("current_health"):
		_update_player_current_health_control()


func _on_arena_slider_changed(value: float, prop_name: String) -> void:
	if _suppress_sync or _arenas.is_empty():
		return
	if not _arena_property_controls.has(prop_name):
		return
	var info: Dictionary = _arena_property_controls[prop_name]
	var is_int: bool = info.get("is_int", false)
	var label: Label = info.get("label") as Label
	if is_int:
		var new_value_int: int = int(round(value))
		for arena in _arenas:
			if not is_instance_valid(arena):
				continue
			arena.set(prop_name, new_value_int)
		if label != null:
			label.text = _format_value(float(new_value_int), true)
	else:
		for arena in _arenas:
			if not is_instance_valid(arena):
				continue
			arena.set(prop_name, value)
		if label != null:
			label.text = _format_value(value, false)
	_refresh_arena_visuals()


func _update_boss_current_health_control() -> void:
	var info: Dictionary = _boss_property_controls.get("current_health", {})
	var slider: HSlider = info.get("slider") as HSlider
	var label: Label = info.get("label") as Label
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
	if label != null:
		label.text = _format_value(clamped, true)


func _update_player_current_health_control() -> void:
	var info: Dictionary = _player_property_controls.get("current_health", {})
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


func _format_value(value: float, is_int: bool) -> String:
	return String.num(value, 0 if is_int else 2)


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
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_player_save_pressed() -> void:
	if _player == null:
		return
	var data := _collect_player_values(_player)
	_write_player_config(data)


func _on_player_reset_pressed() -> void:
	_on_player_save_pressed()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_arena_save_pressed() -> void:
	if _arena == null:
		return
	var data := _collect_arena_values(_arena)
	_write_arena_config(data)


func _on_arena_reset_pressed() -> void:
	_on_arena_save_pressed()
	get_tree().paused = false
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
			boss.set(key, data[key])
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
			arena.set(key, data[key])


func _collect_boss_values(boss: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in boss.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "":
			continue
		values[prop_name] = boss.get(prop_name)
	return values


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


func _collect_arena_values(arena: Node) -> Dictionary:
	var values: Dictionary = {}
	for prop in arena.get_property_list():
		if not _is_tweakable_property(prop):
			continue
		var prop_name: String = prop.get("name", "")
		if prop_name == "":
			continue
		values[prop_name] = arena.get(prop_name)
	return values


func _write_boss_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("boss", key, values[key])
	var err := config.save("user://boss_config.cfg")
	if err != OK:
		push_warning("Failed to write boss config")


func _write_player_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("player", key, values[key])
	var err := config.save("user://player_config.cfg")
	if err != OK:
		push_warning("Failed to write player config")


func _write_arena_config(values: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in values.keys():
		config.set_value("arena", key, values[key])
	var err := config.save("user://arena_config.cfg")
	if err != OK:
		push_warning("Failed to write arena config")


func _read_boss_config() -> Dictionary:
	var config := ConfigFile.new()
	var err := config.load("user://boss_config.cfg")
	if err != OK:
		return {}
	if not config.has_section("boss"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("boss"):
		result[key] = config.get_value("boss", key)
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
	var config := ConfigFile.new()
	var err := config.load("user://arena_config.cfg")
	if err != OK:
		return {}
	if not config.has_section("arena"):
		return {}
	var result: Dictionary = {}
	for key in config.get_section_keys("arena"):
		result[key] = config.get_value("arena", key)
	return result
