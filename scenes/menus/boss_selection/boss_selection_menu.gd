extends Control

signal boss_selected

@export var arena_config_dir: String = "res://config/arenas/"
@onready var buttons_container: VBoxContainer = %BossButtonsContainer


func _ready() -> void:
	_refresh_boss_list()


func _refresh_boss_list() -> void:
	# Clear existing dynamic buttons (keep label and back button)
	for child in buttons_container.get_children():
		child.queue_free()

	var dir = DirAccess.open(arena_config_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".cfg"):
				_create_boss_button(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path: ", arena_config_dir)


func _create_boss_button(file_name: String) -> void:
	var arena_id = file_name.trim_suffix(".cfg")
	var button = Button.new()

	# Format name: "dvd_boss_arena" -> "Dvd Boss Arena"
	var display_name = arena_id.replace("_", " ").capitalize()
	button.text = display_name
	button.custom_minimum_size = Vector2(300, 60)

	button.pressed.connect(
		func():
			GameState.set_selected_arena(arena_id)
			boss_selected.emit()
	)

	buttons_container.add_child(button)


func _on_back_button_pressed() -> void:
	queue_free()
