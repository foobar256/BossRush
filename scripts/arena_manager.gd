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

	# Parse arena data
	_current_arena_data = {}

	# Get arena bounds
	if config.has_section_key("arena", "bounds"):
		var loaded_bounds: Rect2 = config.get_value("arena", "bounds")
		# Always center arena bounds around the world origin.
		loaded_bounds.position = -loaded_bounds.size * 0.5
		_current_arena_data.bounds = loaded_bounds
	else:
		var fallback_bounds := Rect2(0, 0, 1280, 720)
		fallback_bounds.position = -fallback_bounds.size * 0.5
		_current_arena_data.bounds = fallback_bounds  # Default fallback

	# Get arena visuals
	if config.has_section_key("arena", "line_color"):
		_current_arena_data.line_color = config.get_value("arena", "line_color")
	else:
		_current_arena_data.line_color = Color(0.4, 0.4, 0.5, 1)

	if config.has_section_key("arena", "line_width"):
		_current_arena_data.line_width = config.get_value("arena", "line_width")
	else:
		_current_arena_data.line_width = 2.0

	# Get player spawn
	if config.has_section_key("player", "spawn_position"):
		_player_spawn = config.get_value("player", "spawn_position")
	else:
		_player_spawn = Vector2(640, 360)  # Center as fallback

	# Get boss spawn
	if config.has_section_key("boss", "spawn_position"):
		var boss_spawn = config.get_value("boss", "spawn_position")
		_boss_spawns = [boss_spawn]
	else:
		_boss_spawns = []

	# Get boss scene and properties
	_current_arena_data.boss_properties = {}
	if config.has_section("boss"):
		for key in config.get_section_keys("boss"):
			if key == "scene":
				_current_arena_data.boss_scene = config.get_value("boss", "scene")
			elif key != "spawn_position":
				_current_arena_data.boss_properties[key] = config.get_value("boss", key)

	# Create the visual bounds
	_create_bounds_visual()

	# Emit success signal
	arena_created.emit(_current_arena_data)

	return true


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


## Get the bounds visual node (useful for debugging)
func get_bounds_visual() -> Node2D:
	return _bounds_visual


## Get current arena data
func get_arena_data() -> Dictionary:
	return _current_arena_data.duplicate()
