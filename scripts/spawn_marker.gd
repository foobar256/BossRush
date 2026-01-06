extends Node2D

enum Shape { CIRCLE, RECTANGLE }

@export var shape: Shape = Shape.CIRCLE
# Radius for circle (using x), width/height for rectangle
@export var marker_size: Vector2 = Vector2(48.0, 48.0)
@export var marker_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var line_width: float = 2.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if shape == Shape.CIRCLE:
		draw_arc(Vector2.ZERO, marker_size.x, 0, TAU, 64, marker_color, line_width, true)
	else:
		var rect = Rect2(-marker_size * 0.5, marker_size)
		draw_rect(rect, marker_color, false, line_width)
