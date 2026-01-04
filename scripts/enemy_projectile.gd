extends Node2D

@export var speed: float = 400.0
@export var radius: float = 6.0
@export var color: Color = Color(0.4, 0.6, 0.8, 1)  # Ice blue (softened)
@export var damage: float = 15.0

var direction: Vector2 = Vector2.RIGHT
var bounds: Rect2 = Rect2(0, 0, 1280, 720)


func _ready() -> void:
	color = GameColors.PROJECTILE_ENEMY


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
		# Player doesn't have a rect, just a position and radius
		var p_radius = 6.0
		if player.has_method("get"):
			p_radius = player.get("radius")

		if global_position.distance_to(player.global_position) < (radius + p_radius):
			if player.has_method("take_damage"):
				player.take_damage(damage)
			queue_free()
			break


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
