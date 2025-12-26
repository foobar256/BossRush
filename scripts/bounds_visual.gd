extends Node2D

@export var bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export var line_color: Color = Color(0.9, 0.9, 0.9, 1)
@export var line_width: float = 2.0


func get_bounds() -> Rect2:
	return bounds


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(bounds, line_color, false, line_width)
