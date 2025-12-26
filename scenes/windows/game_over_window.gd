extends Control

signal restart_pressed
signal main_menu_pressed

@onready var _game_over_label: Label = %GameOverLabel
@onready var _restart_button: Button = %RestartButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
