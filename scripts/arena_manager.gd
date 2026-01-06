extends Node2D
## Manages arena creation and configuration from cfg files
##
## This script loads arena configurations and creates the arena bounds,
## player spawn points, and boss spawns based on the configuration.

signal arena_created(arena_data: Dictionary)
signal arena_failed(error: String)

@export var default_arena_path: String = "res://config/arenas/"

var _current_arena_data: Dictionary = {}
var _bounds_visual: Node2D = null
var _player_spawn: Vector2 = Vector2.ZERO
var _boss_spawns: Array[Vector2] = []
var _spawn_markers: Array[Node2D] = []


func _ready() -> void:
	add_to_group("arena_manager")


## Load and create an arena from a configuration file
## arena_name: name of the cfg file without extension (e.g., "dvd_boss_arena")
func create_arena(arena_name: String) -> bool:
	var config_path = default_arena_path + arena_name + ".cfg"

	# Load the config file
	var config := ConfigFile.new()
	var err := config.load(config_path)

	if err != OK:
		arena_failed.emit("Failed to load arena config: " + config_path)
		return false

	var error_msg := ""
	_current_arena_data = {}

	# Get arena bounds
	if config.has_section_key("arena", "bounds"):
		var loaded_bounds = _parse_value(config.get_value("arena", "bounds"))
		if loaded_bounds is Rect2:
			# Always center arena bounds around the world origin.
			loaded_bounds.position = -loaded_bounds.size * 0.5
			_current_arena_data.bounds = loaded_bounds
		else:
			error_msg = "Invalid bounds type in arena config"
	else:
		error_msg = "Missing [arena] bounds in config"

	if error_msg == "":
		# Get arena visuals
		_current_arena_data.line_color = config.get_value(
			"arena", "line_color", Color(0.4, 0.4, 0.5, 1)
		)
		_current_arena_data.line_width = config.get_value("arena", "line_width", 2.0)
		_current_arena_data.show_spawn_points = config.get_value(
			"arena", "show_spawn_points", false
		)

		# Get player spawn
		if config.has_section_key("player", "spawn_position"):
			_player_spawn = _parse_value(config.get_value("player", "spawn_position"))
			if not _player_spawn is Vector2:
				error_msg = "Invalid player spawn_position in config"
		else:
			error_msg = "Missing [player] spawn_position in config"

	if error_msg == "":
		# Get boss spawn
		if config.has_section_key("boss", "spawn_position"):
			var boss_spawn = _parse_value(config.get_value("boss", "spawn_position"))
			if boss_spawn is Vector2:
				_boss_spawns = [boss_spawn]
			else:
				error_msg = "Invalid boss spawn_position in config"
		else:
			error_msg = "Missing [boss] spawn_position in config"

	if error_msg == "":
		# Get boss scene and properties
		if not config.has_section("boss") or not config.has_section_key("boss", "scene"):
			error_msg = "Missing [boss] section or scene path in config"
		else:
			_current_arena_data.boss_properties = {}
			for key in config.get_section_keys("boss"):
				if key == "scene":
					_current_arena_data.boss_scene = config.get_value("boss", "scene")
				elif key != "spawn_position":
					_current_arena_data.boss_properties[key] = _parse_value(
						config.get_value("boss", key)
					)

	if error_msg != "":
		arena_failed.emit(error_msg)
		return false

	# Create the visual bounds
	_create_bounds_visual()

	# Create spawn markers if enabled
	_create_spawn_markers()

	# Emit success signal
	arena_created.emit(_current_arena_data)

	return true


func _parse_value(value: Variant) -> Variant:
	if value is Dictionary and value.has("x") and value.has("y"):
		if value.has("width") and value.has("height"):
			return Rect2(
				float(value["x"]), float(value["y"]), float(value["width"]), float(value["height"])
			)
		return Vector2(float(value["x"]), float(value["y"]))
	return value


## Get the player spawn position for the current arena
func get_player_spawn() -> Vector2:
	return _player_spawn


## Get all boss spawn positions for the current arena
func get_boss_spawns() -> Array[Vector2]:
	return _boss_spawns.duplicate()


## Get the arena bounds
func get_bounds() -> Rect2:
	if _current_arena_data.has("bounds"):
		return _current_arena_data.bounds
	return Rect2(0, 0, 1280, 720)  # Default fallback


## Get the boss scene path if configured
func get_boss_scene() -> String:
	if _current_arena_data.has("boss_scene"):
		return _current_arena_data.boss_scene
	return ""


## Clear the current arena
func clear_arena() -> void:
	if _bounds_visual != null:
		_bounds_visual.queue_free()
		_bounds_visual = null

	for marker in _spawn_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_spawn_markers.clear()

	_current_arena_data.clear()
	_player_spawn = Vector2.ZERO
	_boss_spawns.clear()


## Create the bounds visual node
func _create_bounds_visual() -> void:
	# Remove existing bounds visual
	if _bounds_visual != null:
		_bounds_visual.queue_free()
		_bounds_visual = null

	# Create new bounds visual
	var bounds_script = load("res://scripts/bounds_visual.gd")
	_bounds_visual = Node2D.new()
	_bounds_visual.set_script(bounds_script)
	_bounds_visual.name = "ArenaBounds"

	# Set the bounds properties
	if _current_arena_data.has("bounds"):
		_bounds_visual.bounds = _current_arena_data.bounds
	if _current_arena_data.has("line_color"):
		_bounds_visual.line_color = _current_arena_data.line_color
	if _current_arena_data.has("line_width"):
		_bounds_visual.line_width = _current_arena_data.line_width

	# Add to scene
	add_child(_bounds_visual)
	_bounds_visual.owner = owner if owner != null else get_parent()


## Create visual markers for spawn points
func _create_spawn_markers() -> void:
	# Clear existing markers
	for marker in _spawn_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_spawn_markers.clear()

	if not _current_arena_data.get("show_spawn_points", false):
		return

	var marker_script = load("res://scripts/spawn_marker.gd")

	# Create player spawn marker
	var player_marker = Node2D.new()
	player_marker.set_script(marker_script)
	player_marker.name = "PlayerSpawnMarker"
	player_marker.shape = 0  # CIRCLE
	player_marker.marker_size = Vector2(48.0, 48.0)  # Default player radius
	player_marker.marker_color = Color(0.2, 0.8, 0.2, 0.5)  # Greenish for player
	player_marker.position = _player_spawn
	add_child(player_marker)
	_spawn_markers.append(player_marker)

	# Create boss spawn marker(s)
	for spawn_pos in _boss_spawns:
		var boss_marker = Node2D.new()
		boss_marker.set_script(marker_script)
		boss_marker.name = "BossSpawnMarker"
		boss_marker.shape = 1  # RECTANGLE

		# Try to determine boss size from properties
		var boss_size = Vector2(100.0, 100.0)  # Default fallback
		if _current_arena_data.has("boss_properties"):
			var props = _current_arena_data.boss_properties
			if props.has("boss_size"):
				boss_size = props["boss_size"]
			elif props.has("size"):
				var s = props["size"]
				boss_size = Vector2(s, s)

		boss_marker.marker_size = boss_size
		boss_marker.marker_color = Color(0.8, 0.2, 0.2, 0.5)  # Reddish for boss
		boss_marker.position = spawn_pos
		add_child(boss_marker)
		_spawn_markers.append(boss_marker)


## Get the bounds visual node (useful for debugging)
func get_bounds_visual() -> Node2D:
	return _bounds_visual


## Get current arena data
func get_arena_data() -> Dictionary:
	return _current_arena_data.duplicate()


## Get the path to the current arena's config file
func get_current_config_path() -> String:
	var arena_name = GameState.get_selected_arena()
	if arena_name == "":
		arena_name = "habbakuk_arena"
	return default_arena_path + arena_name + ".cfg"
