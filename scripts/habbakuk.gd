extends Node2D

signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 600.0
@export var current_health: float = 600.0
@export var max_shield: float = 300.0
@export var current_shield: float = 300.0
@export var size: float = 180.0
@export var speed: float = 100.0
@export var ice_patch_scene: PackedScene
@export var frost_bolt_scene: PackedScene
@export var bullet_scene: PackedScene
@export var rocket_scene: PackedScene

var _boss_bar: Node = null
var _velocity: Vector2 = Vector2.ZERO
var _is_combat_active: bool = false
var _gun_timer: float = 0.0
var _rocket_timer: float = 0.0
var _ice_patch_timer: float = 0.0

@onready var body: Polygon2D = $Body
@onready var hull_details: Node2D = $HullDetails


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	current_health = clamp(current_health, 0.0, max_health)
	_boss_bar = _find_boss_bar()
	call_deferred("_sync_boss_bar")
	_velocity = Vector2.RIGHT.rotated(randf() * TAU) * speed
	_setup_visuals()


func start_combat() -> void:
	_is_combat_active = true


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	if current_shield > 0.0:
		var shield_damage = min(current_shield, amount)
		current_shield -= shield_damage
		amount -= shield_damage
	if amount > 0.0:
		current_health = max(current_health - amount, 0.0)

	emit_signal("health_changed", current_health, max_health)
	_sync_boss_bar()
	if current_health <= 0.0:
		emit_signal("died")
		queue_free()


func get_bounds_rect() -> Rect2:
	var half := size * 0.5
	return Rect2(global_position - Vector2(half, half), Vector2(size, size))


func _physics_process(delta: float) -> void:
	if not _is_combat_active:
		return

	# Slow, heavy movement
	global_position += _velocity * delta
	var bounds = _get_world_bounds()
	var half = size * 0.5

	if global_position.x < bounds.position.x + half:
		_velocity.x = abs(_velocity.x)
	elif global_position.x > bounds.position.x + bounds.size.x - half:
		_velocity.x = -abs(_velocity.x)

	if global_position.y < bounds.position.y + half:
		_velocity.y = abs(_velocity.y)
	elif global_position.y > bounds.position.y + bounds.size.y - half:
		_velocity.y = -abs(_velocity.y)

	# Attack Timers
	_gun_timer -= delta
	if _gun_timer <= 0.0:
		_fire_cannons()
		_gun_timer = randf_range(0.8, 1.5)

	_rocket_timer -= delta
	if _rocket_timer <= 0.0 and current_health < max_health * 0.75:
		_fire_rockets()
		_rocket_timer = randf_range(4.0, 6.0)

	_ice_patch_timer -= delta
	if _ice_patch_timer <= 0.0:
		_drop_ice_patch()
		_ice_patch_timer = randf_range(3.0, 5.0)


func _fire_cannons() -> void:
	if bullet_scene == null:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Fire 3 bullets in a small spread
	var base_dir = (player.global_position - global_position).normalized()
	for i in range(-1, 2):
		var dir = base_dir.rotated(i * 0.2)
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		if bullet.has_method("setup"):
			bullet.setup(dir, _get_world_bounds(), 10.0)
		if "color" in bullet:
			bullet.color = Color(1.0, 0.8, 0.2)  # Tracer/Shell color


func _fire_rockets() -> void:
	if rocket_scene == null:
		return
	for i in range(4):
		var rocket = rocket_scene.instantiate()
		get_parent().add_child(rocket)
		# Launch from corners
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * (size * 0.4)
		rocket.global_position = global_position + offset
		if rocket.has_method("setup"):
			var launch_dir = offset.normalized()
			rocket.setup(launch_dir, _get_world_bounds(), 25.0)
		# Rockets should have tracking, which we'll handle in their script


func _drop_ice_patch() -> void:
	if ice_patch_scene == null:
		return
	var patch = ice_patch_scene.instantiate()
	get_parent().add_child(patch)
	patch.global_position = global_position


func _setup_visuals() -> void:
	if body == null:
		return
	# A more rectangular ship-like shape
	var points = PackedVector2Array(
		[
			Vector2(-size * 0.4, -size * 0.5),  # Bow
			Vector2(size * 0.4, -size * 0.5),
			Vector2(size * 0.5, -size * 0.2),
			Vector2(size * 0.5, size * 0.4),
			Vector2(size * 0.3, size * 0.5),
			Vector2(-size * 0.3, size * 0.5),
			Vector2(-size * 0.5, size * 0.4),
			Vector2(-size * 0.5, -size * 0.2),
		]
	)
	body.polygon = points
	body.color = Color(0.6, 0.7, 0.8, 1.0)  # Pykrete color


func _get_world_bounds() -> Rect2:
	var arena_manager = get_tree().get_first_node_in_group("arena_manager")
	if arena_manager != null and arena_manager.has_method("get_bounds"):
		return arena_manager.get_bounds()
	return Rect2(Vector2.ZERO, get_viewport_rect().size)


func _find_boss_bar() -> Node:
	return get_tree().get_first_node_in_group("boss_health_bar")


func _sync_boss_bar() -> void:
	if _boss_bar != null and _boss_bar.has_method("update_boss_stats"):
		_boss_bar.update_boss_stats(self, current_health, max_health, current_shield, max_shield)
