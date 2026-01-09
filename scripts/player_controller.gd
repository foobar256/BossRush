extends Node2D

signal died

@export var move_speed: float = 220.0
@export var radius: float = 48.0
@export var dot_color: Color = Color.WHITE
@export var outline_color: Color = Color.BLACK
@export var outline_thickness: float = 6.0
@export var show_debug_hitbox: bool = false
@export var fire_cooldown: float = 0.12  # Fallback
@export var current_weapon: WeaponData = preload("res://resources/weapons/pistol.tres")
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

var _sprite: Sprite2D

@onready var _projectile_parent: Node = _find_projectile_parent()


func _ready() -> void:
	dot_color = Color.WHITE
	add_to_group("player")
	current_health = clamp(current_health, 0.0, max_health)

	_setup_player_sprite()

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
		# Blinking effect
		var blink_speed = 12.0
		var is_visible = int(_invincibility_timer * blink_speed * 2.0) % 2 == 0
		modulate.a = 1.0 if is_visible else 0.4
		if _invincibility_timer <= 0.0:
			modulate.a = 1.0
	elif modulate.a != 1.0:
		modulate.a = 1.0

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
	if current_weapon and current_weapon.is_auto:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_try_fire()
	else:
		if Input.is_action_just_pressed("fire"):  # Assuming "fire" action exists or we use mouse left
			_try_fire()


func _draw() -> void:
	if show_debug_hitbox:
		# Draw hitbox in red on top
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color.RED, 2.0, true)

	# Fallback: if sprite isn't working, draw a red dot in the middle
	if _sprite == null or _sprite.texture == null:
		draw_circle(Vector2.ZERO, radius, Color.RED)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _is_dead or _invincibility_timer > 0.0:
		return
	current_health = max(current_health - amount, 0.0)
	_invincibility_timer = invincibility_duration
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
	var ProjectileScene = preload("res://scenes/game_scene/projectile.tscn")
	if _fire_timer > 0.0 or ProjectileScene == null or current_weapon == null:
		return

	var mouse_pos = get_global_mouse_position()
	var direction := mouse_pos - global_position
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()

	var spawn_offset := radius + 8.0
	var base_rotation = direction.angle()
	var spread_rad = deg_to_rad(current_weapon.spread_degrees)

	for i in range(current_weapon.projectiles_per_shot):
		var shot_direction = direction
		if current_weapon.projectiles_per_shot > 1:
			var offset = (randf() - 0.5) * spread_rad
			shot_direction = Vector2.from_angle(base_rotation + offset)

		var projectile := ProjectileScene.instantiate()
		if projectile == null:
			continue

		_projectile_parent.add_child(projectile)
		projectile.global_position = global_position + direction * spawn_offset
		if projectile.has_method("setup"):
			projectile.setup(shot_direction, bounds, current_weapon.damage)
		projectile.speed = current_weapon.projectile_speed

	_fire_timer = current_weapon.fire_cooldown


func set_weapon(weapon: WeaponData) -> void:
	current_weapon = weapon
	# Reset fire timer if the new weapon has a significantly different cooldown
	_fire_timer = min(_fire_timer, current_weapon.fire_cooldown)


func _check_contact_damage() -> void:
	if _invincibility_timer > 0.0 or contact_damage <= 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not enemy.has_method("get_bounds_rect"):
			continue
		var rect: Rect2 = enemy.get_bounds_rect()

		# Better hitbox check: check if circle (player) overlaps rect (enemy)
		var closest_point = Vector2(
			clamp(global_position.x, rect.position.x, rect.position.x + rect.size.x),
			clamp(global_position.y, rect.position.y, rect.position.y + rect.size.y)
		)

		if global_position.distance_to(closest_point) < radius:
			take_damage(contact_damage)
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


func _setup_player_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "PlayerSprite"
	add_child(_sprite)
	_sprite.centered = true
	_sprite.show_behind_parent = true

	var global_path = ProjectSettings.globalize_path("res://assets/player.webp")
	var img = Image.load_from_file(global_path)
	if img:
		_sprite.texture = ImageTexture.create_from_image(img)
	else:
		_sprite.texture = null

	if _sprite.texture:
		var tex_size = _sprite.texture.get_size()
		# The baked sprite includes the border.
		# Original radius 48, thickness 6 -> outer radius 51, total diameter 102.
		var target_size = (radius + outline_thickness / 2.0) * 2.0
		var scale_factor = target_size / tex_size.x
		_sprite.scale = Vector2(scale_factor, scale_factor)
	else:
		# Fallback if texture fails to load
		_sprite.queue_free()
		_sprite = null
		# Redraw the white dot in _draw if sprite fails
		queue_redraw()
