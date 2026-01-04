extends Node2D

signal died

@export var move_speed: float = 220.0
@export var radius: float = 6.0
@export var dot_color: Color = Color(0.9, 0.86, 0.8, 1)
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 650.0
@export var projectile_damage: float = 10.0
@export var fire_cooldown: float = 0.12
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var contact_damage: float = 10.0
@export var invincibility_duration: float = 0.6
@export var knockback_distance: float = 32.0
@export var knockback_speed: float = 520.0
@export var knockback_duration: float = 0.12
@export var bounds: Rect2 = Rect2(0, 0, 1280, 720)  # Default, will be set from arena config
@export var acceleration: float = 2400.0
@export var friction: float = 12.0
@export var friction_multiplier: float = 1.0

var _fire_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _knockback_timer: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _is_dead: bool = false
var _is_combat_active: bool = false
var _arena_manager: Node2D = null

@onready var _projectile_parent: Node = _find_projectile_parent()


func _ready() -> void:
	dot_color = GameColors.TEXT
	add_to_group("player")
	current_health = clamp(current_health, 0.0, max_health)

	# Find arena manager
	_arena_manager = get_tree().get_first_node_in_group("arena_manager")
	if _arena_manager == null:
		# Try to find it by name
		var root = get_tree().current_scene
		if root != null:
			_arena_manager = root.get_node_or_null("ArenaManager")

	# Get bounds from arena manager if available
	if _arena_manager != null:
		if _arena_manager.has_method("get_bounds"):
			bounds = _arena_manager.get_bounds()
		# Set spawn position from arena manager
		if _arena_manager.has_method("get_player_spawn"):
			var spawn_pos = _arena_manager.get_player_spawn()
			global_position = spawn_pos

		# Connect to arena_created signal to update bounds if they change
		if _arena_manager.has_signal("arena_created"):
			_arena_manager.arena_created.connect(_on_arena_created)


func _on_arena_created(arena_data: Dictionary) -> void:
	if arena_data.has("bounds"):
		bounds = arena_data.bounds
	if _arena_manager.has_method("get_player_spawn"):
		global_position = _arena_manager.get_player_spawn()

	_sync_health_bar()
	queue_redraw()


func start_combat() -> void:
	_is_combat_active = true


func _process(delta: float) -> void:
	if _is_dead:
		return
	if _invincibility_timer > 0.0:
		_invincibility_timer = max(_invincibility_timer - delta, 0.0)
	if _knockback_timer > 0.0:
		position += _knockback_velocity * delta
		_knockback_timer = max(_knockback_timer - delta, 0.0)

	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	var target_vel = input_vector.normalized() * move_speed
	var current_friction = friction * friction_multiplier

	if input_vector.length_squared() > 0.0:
		_velocity = _velocity.move_toward(target_vel, acceleration * delta)
	else:
		_velocity = _velocity.move_toward(Vector2.ZERO, current_friction * move_speed * delta)

	position += _velocity * delta
	var min_pos := bounds.position
	var max_pos := bounds.position + bounds.size
	position.x = clamp(position.x, min_pos.x, max_pos.x)
	position.y = clamp(position.y, min_pos.y, max_pos.y)
	_check_contact_damage()
	_fire_timer = max(_fire_timer - delta, 0.0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_fire()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, dot_color)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _is_dead:
		return
	current_health = max(current_health - amount, 0.0)
	_sync_health_bar()
	if current_health <= 0.0:
		_die()


func _sync_health_bar() -> void:
	var bar := get_tree().get_first_node_in_group("player_bar")
	if bar != null and bar.has_method("set_health"):
		bar.set_health(current_health, max_health)


func _die() -> void:
	_is_dead = true
	died.emit()


func _try_fire() -> void:
	if _fire_timer > 0.0 or projectile_scene == null:
		return
	var direction := get_global_mouse_position() - global_position
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	var projectile := projectile_scene.instantiate()
	if projectile == null:
		return
	var spawn_offset := radius + 8.0
	_projectile_parent.add_child(projectile)
	projectile.global_position = global_position + direction * spawn_offset
	if projectile.has_method("setup"):
		projectile.setup(direction, bounds, projectile_damage)
	projectile.speed = projectile_speed
	_fire_timer = fire_cooldown


func _check_contact_damage() -> void:
	if _invincibility_timer > 0.0 or contact_damage <= 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not enemy.has_method("get_bounds_rect"):
			continue
		var rect: Rect2 = enemy.get_bounds_rect()
		if rect.has_point(global_position):
			take_damage(contact_damage)
			_invincibility_timer = invincibility_duration
			_apply_contact_knockback(rect)
			return


func _apply_contact_knockback(rect: Rect2) -> void:
	var rect_center := rect.position + rect.size * 0.5
	var dir := global_position - rect_center
	if dir.length_squared() <= 0.0001:
		dir = Vector2.RIGHT
	var normalized := dir.normalized()
	var half := rect.size * 0.5
	var push_radius: float = max(half.x, half.y) + radius + knockback_distance
	global_position = rect_center + normalized * push_radius
	_knockback_velocity = normalized * knockback_speed
	_knockback_timer = knockback_duration


func _find_projectile_parent() -> Node:
	var parent := get_tree().get_first_node_in_group("projectile_container")
	if parent != null:
		return parent
	return get_tree().current_scene
