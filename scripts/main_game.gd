extends Node2D

@onready var _player: Node2D = $Player
@onready var _game_over_window: Control = $GameOverWindow


func _ready() -> void:
	if _player != null and _player.has_signal("died"):
		_player.died.connect(_on_player_died)
	if _game_over_window != null:
		_game_over_window.restart_pressed.connect(_on_restart_pressed)
		_game_over_window.main_menu_pressed.connect(_on_main_menu_pressed)


func _on_player_died() -> void:
	if _game_over_window != null:
		_game_over_window.visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
