extends CanvasLayer

signal countdown_finished

var _timer: SceneTreeTimer
var _countdown_value: int = 3

@onready var label: Label = $CenterContainer/Label

func _ready() -> void:
	if label:
		label.add_theme_color_override("font_outline_color", GameColors.BACKGROUND)
		label.add_theme_color_override("font_color", GameColors.TEXT)

func start_countdown() -> void:
	visible = true
	_countdown_value = 3
	_update_label()
	_tick()


func _tick() -> void:
	if _countdown_value > 0:
		label.text = str(_countdown_value)
		# Animation could be added here
		_countdown_value -= 1
		get_tree().create_timer(1.0, true).timeout.connect(_tick)
	elif _countdown_value == 0:
		label.text = "GO!"
		_countdown_value -= 1
		get_tree().create_timer(1.0, true).timeout.connect(_tick)
	else:
		visible = false
		countdown_finished.emit()


func _update_label() -> void:
	if label:
		label.text = str(_countdown_value)
