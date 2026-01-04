extends Control

signal restart_pressed
signal main_menu_pressed

@onready var _game_over_label: Label = %GameOverLabel
@onready var _restart_button: Button = %RestartButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	# Set process mode to always allow input even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	var bg = get_node_or_null("Background")
	if bg:
		bg.color = GameColors.BACKGROUND
		bg.color.a = 0.8

	# Connect button signals
	if _restart_button:
		_restart_button.pressed.connect(_on_restart_button_pressed)
	if _main_menu_button:
		_main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	# Ensure window is centered and hidden initially
	visible = false


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_main_menu_button_pressed() -> void:
	main_menu_pressed.emit()
