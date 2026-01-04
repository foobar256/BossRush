extends "res://scripts/enemy_projectile.gd"

@export var turn_speed: float = 2.0
@export var acceleration: float = 200.0
@export var max_speed: float = 500.0

var _lifetime: float = 4.0


func _ready() -> void:
	color = GameColors.ROCKET


func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
		return

	# Accelerate
	speed = min(speed + acceleration * delta, max_speed)

	# Track player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var target_dir = (player.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()

	super._process(delta)


func _draw() -> void:
	# Rocket shape
	var tip = direction * radius * 1.5
	var base = -direction * radius
	var side = direction.rotated(PI / 2) * radius * 0.8
	var points = PackedVector2Array([tip, base + side, base - side])
	draw_colored_polygon(points, color)
