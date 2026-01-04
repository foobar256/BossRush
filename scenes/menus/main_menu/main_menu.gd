extends MainMenu
## Main menu extension that adds options.
## The scene adds a 'Continue' button if a game is in progress.

## Optional scene to open when the player clicks a 'Level Select' button.
@export var level_select_packed_scene: PackedScene
## Optional scene to open when the player clicks a 'New Game' button.
@export var boss_selection_packed_scene: PackedScene
## If true, have the player confirm before starting a new game if a game is in progress.
@export var confirm_new_game: bool = true

@onready var continue_game_button = %ContinueGameButton
@onready var level_select_button = %LevelSelectButton
@onready var new_game_confirmation = %NewGameConfirmation


func load_game_scene() -> void:
	GameState.start_game()
	super.load_game_scene()


func new_game() -> void:
	if confirm_new_game and continue_game_button.visible:
		new_game_confirmation.show()
	else:
		_open_boss_selection()


func _open_boss_selection() -> void:
	if boss_selection_packed_scene == null:
		GameState.reset()
		load_game_scene()
		return

	var boss_selection_scene := _open_sub_menu(boss_selection_packed_scene)
	if boss_selection_scene.has_signal("boss_selected"):
		boss_selection_scene.connect(
			"boss_selected",
			func():
				GameState.reset()
				load_game_scene()
		)


func _add_level_select_if_set() -> void:
	if level_select_packed_scene == null:
		return
	if GameState.get_levels_reached() <= 1:
		return
	level_select_button.show()


func _show_continue_if_set() -> void:
	if GameState.get_current_level_path().is_empty():
		return
	continue_game_button.show()


func _ready() -> void:
	super._ready()
	_add_level_select_if_set()
	_show_continue_if_set()
	
	var bg = get_node_or_null("BackgroundColor")
	if bg:
		bg.color = GameColors.BACKGROUND


func _on_continue_game_button_pressed() -> void:
	GameState.continue_game()
	load_game_scene()


func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)


func _on_new_game_confirmation_confirmed() -> void:
	_open_boss_selection()
