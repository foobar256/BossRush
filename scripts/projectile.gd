extends Node2D

@export var speed: float = 650.0
@export var radius: float = 4.0
@export var color: Color = Color(1, 1, 1, 1)
@export var damage: float = 10.0

var direction: Vector2 = Vector2.RIGHT
var bounds: Rect2 = Rect2(0, 0, 1280, 720)


func setup(direction_in: Vector2, bounds_in: Rect2, damage_in: float) -> void:
	direction = direction_in.normalized()
	bounds = bounds_in
	damage = damage_in
	queue_redraw()


func _process(delta: float) -> void:
	position += direction * speed * delta
	if not bounds.has_point(global_position):
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("get_bounds_rect"):
			continue
		if enemy.get_bounds_rect().has_point(global_position):
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			queue_free()
			break


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
