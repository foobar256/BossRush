extends Node2D

var _game_over_window: Control

@onready var _player: Node2D = $Player
@onready var _arena_manager: Node2D = $ArenaManager
@onready var _crosshair_cursor: CanvasLayer = $Crosshair
@onready var _countdown_ui: CanvasLayer = $CountdownUI


func _ready() -> void:
	# Get game over window dynamically
	_game_over_window = get_node_or_null("GameOverWindow")

	# Create the arena first
	if _arena_manager != null:
		_arena_manager.create_arena("dvd_boss_arena")
		# Wait a frame for arena to be created, then spawn boss and set player position
		call_deferred("_setup_arena_elements")

	if _player != null and _player.has_signal("died"):
		_player.died.connect(_on_player_died)

	# Setup game over window connections
	if _game_over_window != null:
		if _game_over_window.has_signal("restart_pressed"):
			_game_over_window.restart_pressed.connect(_on_restart_pressed)
		if _game_over_window.has_signal("main_menu_pressed"):
			_game_over_window.main_menu_pressed.connect(_on_main_menu_pressed)
		_game_over_window.visible = false

	if _countdown_ui != null:
		_countdown_ui.countdown_finished.connect(_on_countdown_finished)


func _setup_arena_elements() -> void:
	if _arena_manager == null:
		return

	# Set player bounds from arena
	if _player != null:
		_player.bounds = _arena_manager.get_bounds()

	# Spawn boss
	var boss_scene_path = _arena_manager.get_boss_scene()
	if boss_scene_path == "":
		return

	var boss_scene = load(boss_scene_path)
	if boss_scene == null:
		return

	# Get boss spawn positions
	var boss_spawns = _arena_manager.get_boss_spawns()
	if boss_spawns.is_empty():
		return

	# Spawn boss at first position
	var boss = boss_scene.instantiate()
	if boss == null:
		return

	# Set boss position
	boss.position = boss_spawns[0]

	# Add boss to scene
	add_child(boss)

	# Set player position below boss
	if _player != null:
		# Position player 150 units below boss
		_player.global_position = boss.global_position + Vector2(0, 150)

	# Start countdown
	if _countdown_ui != null:
		_countdown_ui.start_countdown()


func _on_countdown_finished() -> void:
	if _player != null and _player.has_method("start_combat"):
		_player.start_combat()

	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("start_combat"):
			boss.start_combat()


func _on_player_died() -> void:
	if _game_over_window != null:
		_game_over_window.visible = true
		# Process mode needs to be set to allow the window to work while paused
		_game_over_window.process_mode = Node.PROCESS_MODE_ALWAYS
	_set_game_cursor_enabled(false)
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	_set_game_cursor_enabled(true)
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	_set_game_cursor_enabled(false)
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")


func _set_game_cursor_enabled(enabled: bool) -> void:
	if _crosshair_cursor != null and _crosshair_cursor.has_method("set_enabled"):
		_crosshair_cursor.set_enabled(enabled)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if enabled else Input.MOUSE_MODE_VISIBLE
