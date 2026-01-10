extends Node2D

@export var speed: float = 400.0
@export var radius: float = 8.0
@export var color: Color = Color(0.0, 0.0, 1.0, 1) # Blue
@export var damage: float = 15.0

var direction: Vector2 = Vector2.RIGHT
var bounds: Rect2 = Rect2(0, 0, 1280, 720)


func _ready() -> void:
	# Keep the specific color for Blue Lobster
	pass


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

	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var p_radius = 6.0
		if "radius" in player:
			p_radius = player.radius

		if global_position.distance_to(player.global_position) < (radius + p_radius):
			if player.has_method("take_damage"):
				player.take_damage(damage)
			queue_free()
			break


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
