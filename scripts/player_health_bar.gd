extends Control

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var bar_color: Color = Color(0.2, 0.8, 0.3, 1)
@export var back_color: Color = Color(0.12, 0.12, 0.12, 0.85)
@export var outline_color: Color = Color(1, 1, 1, 1)
@export var outline_width: float = 2.0


func _ready() -> void:
	add_to_group("player_bar")
	queue_redraw()


func set_health(current: float, max_value: float) -> void:
	max_health = max_value
	current_health = clamp(current, 0.0, max_health)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, back_color, true)
	var percent := 0.0
	if max_health > 0.0:
		percent = current_health / max_health
	var fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * percent, size.y))
	draw_rect(fill_rect, bar_color, true)
	draw_rect(rect, outline_color, false, outline_width)
