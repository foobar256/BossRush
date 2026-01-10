extends Node2D

signal health_changed(current: float, max: float)
signal died

enum State {
	IDLE,
	CHASE,
	CHARGE,
	BLOB,
	CLAW
}

@export var max_health: float = 500.0
@export var current_health: float = 500.0
@export var max_shield: float = 200.0
@export var current_shield: float = 200.0
@export var boss_size: Vector2 = Vector2(120.0, 80.0)
@export var move_speed: float = 150.0
@export var charge_speed: float = 600.0
@export var bounds_node: NodePath

@export var blob_projectile_scene: PackedScene = preload("res://scenes/game_scene/blue_lobster_projectile.tscn")
@export var blob_damage: float = 15.0
@export var claw_damage: float = 25.0
@export var charge_damage: float = 30.0

@export var text: String = "Blue Lobster"
@export var text_color: Color = Color(1.0, 1.0, 1.0, 1)
@export var font: Font = preload("res://assets/fonts/SourGummy/SourGummy-Bold.ttf")

@export var health_bar_height: float = 8.0
@export var health_bar_back_color: Color = Color(0.12, 0.12, 0.15, 0.85)
@export var health_bar_fill_color: Color = Color(0.8, 0.4, 0.4, 1.0)
@export var shield_bar_fill_color: Color = Color(0.4, 0.6, 0.8, 1.0)
@export var health_bar_offset: float = 6.0
@export var health_bar_path: NodePath

var _state: State = State.IDLE
var _velocity: Vector2 = Vector2.ZERO
var _is_combat_active: bool = false
var _boss_bar: Node = null
var _state_timer: float = 0.0
var _charge_target: Vector2 = Vector2.ZERO
var _charge_duration: float = 0.0
var _cooldown_timer: float = 0.0

@onready var box: ColorRect = $Body
@onready var left_claw: ColorRect = $LeftClaw
@onready var right_claw: ColorRect = $RightClaw
@onready var label: Label = $Label
@onready var health_bar_back: ColorRect = $HealthBarBack
@onready var health_bar_fill: ColorRect = $HealthBarFill
@onready var shield_bar_fill: ColorRect = $ShieldBarFill

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")

	current_health = clamp(current_health, 0.0, max_health)
	_boss_bar = _find_boss_bar()
	call_deferred("_sync_boss_bar")

	_apply_visuals()
	_update_health_bar()

func start_combat() -> void:
	_is_combat_active = true
	_change_state(State.CHASE)

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
	_update_health_bar()

	if current_health <= 0.0:
		emit_signal("died")
		queue_free()

func _physics_process(delta: float) -> void:
	if not _is_combat_active:
		return

	_state_timer -= delta
	_cooldown_timer -= delta

	match _state:
		State.CHASE:
			_process_chase(delta)
		State.CHARGE:
			_process_charge(delta)
		State.BLOB:
			pass # Logic happens in enter state mainly
		State.CLAW:
			pass # Logic happens in enter state mainly

	_move_and_collide(delta)

	# State transitions if timer expired
	if _state_timer <= 0.0:
		_decide_next_state()

func _process_chase(delta: float) -> void:
	var player = _get_player()
	if player:
		var direction = (player.global_position - global_position).normalized()
		_velocity = direction * move_speed
		_look_at_player(player.global_position)

		# If close enough, maybe claw
		var dist = global_position.distance_to(player.global_position)
		if dist < 150.0 and _cooldown_timer <= 0.0:
			_change_state(State.CLAW)
	else:
		_velocity = Vector2.ZERO

func _process_charge(delta: float) -> void:
	# Charge direction is set on enter
	# Check for player collision during charge to deal damage
	var player = _get_player()
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist < (boss_size.x * 0.6): # Approximate hitbox
			if player.has_method("take_damage"):
				player.take_damage(charge_damage * delta) # Continuous damage or single hit? Let's do rapid small damage or pushback
				# For simplicity, let's just rely on projectile logic or simple distance check
				# To avoid spamming damage per frame, we'd need a cooldown per hit, but for now let's just push them?
				# Actually, let's keep it simple.
				pass

func _move_and_collide(delta: float) -> void:
	var bounds := _get_world_bounds()
	if bounds.size == Vector2.ZERO:
		return

	global_position += _velocity * delta

	# Keep in bounds
	var half := boss_size * 0.5
	# Adjust for rotation? Boss is basically a rect for collision here.

	var min_x := bounds.position.x + half.x
	var max_x := bounds.position.x + bounds.size.x - half.x
	var min_y := bounds.position.y + half.y
	var max_y := bounds.position.y + bounds.size.y - half.y

	if global_position.x < min_x: global_position.x = min_x; _velocity.x = 0
	if global_position.x > max_x: global_position.x = max_x; _velocity.x = 0
	if global_position.y < min_y: global_position.y = min_y; _velocity.y = 0
	if global_position.y > max_y: global_position.y = max_y; _velocity.y = 0

	_resolve_collisions()

func _decide_next_state() -> void:
	if _state == State.CHARGE or _state == State.BLOB or _state == State.CLAW:
		_change_state(State.CHASE)
		return

	# In CHASE, decide what to do
	var player = _get_player()
	if not player:
		_change_state(State.IDLE)
		return

	var dist = global_position.distance_to(player.global_position)
	var rand = randf()

	if dist > 400.0:
		if rand < 0.6:
			_change_state(State.CHARGE)
		else:
			_change_state(State.BLOB)
	elif dist > 200.0:
		if rand < 0.5:
			_change_state(State.BLOB)
		else:
			_change_state(State.CHASE) # Continue chasing
			_state_timer = 1.0
	else:
		_change_state(State.CLAW)

func _change_state(new_state: State) -> void:
	_state = new_state
	match _state:
		State.IDLE:
			_velocity = Vector2.ZERO
			_state_timer = 1.0
		State.CHASE:
			_state_timer = randf_range(2.0, 4.0)
		State.CHARGE:
			var player = _get_player()
			if player:
				var direction = (player.global_position - global_position).normalized()
				_velocity = direction * charge_speed
				_state_timer = 1.5 # Charge duration
				_look_at_player(player.global_position)
			else:
				_change_state(State.IDLE)
		State.BLOB:
			_velocity = Vector2.ZERO
			_fire_blob()
			_state_timer = 0.5 # Short pause after shooting
		State.CLAW:
			_velocity = Vector2.ZERO
			_perform_claw()
			_state_timer = 0.5 # Short pause after claw
			_cooldown_timer = 2.0 # Cooldown for claw

func _fire_blob() -> void:
	if not blob_projectile_scene:
		return

	var player = _get_player()
	if not player:
		return

	# Shoot 3 blobs in a spread
	var direction = (player.global_position - global_position).normalized()
	var angles = [-0.2, 0.0, 0.2]

	for angle in angles:
		var blob = blob_projectile_scene.instantiate()
		var dir = direction.rotated(angle)
		blob.position = global_position + dir * 50.0
		blob.setup(dir, _get_world_bounds(), blob_damage)
		get_parent().add_child(blob)

func _perform_claw() -> void:
	# Visual indication + damage check
	# For now, just instant damage if in range
	var player = _get_player()
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist < 200.0: # Reach of claw
		if player.has_method("take_damage"):
			player.take_damage(claw_damage)

	# Animate claws?
	var tween = create_tween()
	tween.tween_property(left_claw, "position:x", left_claw.position.x + 20, 0.1)
	tween.tween_property(left_claw, "position:x", left_claw.position.x, 0.1)

	var tween2 = create_tween()
	tween2.tween_property(right_claw, "position:x", right_claw.position.x - 20, 0.1)
	tween2.tween_property(right_claw, "position:x", right_claw.position.x, 0.1)

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _look_at_player(target_pos: Vector2) -> void:
	# Ideally rotate the whole body or just flip?
	# Since it's a top down view maybe rotate
	var angle = (target_pos - global_position).angle()
	rotation = angle

func _apply_visuals() -> void:
	if box != null:
		box.position = -boss_size * 0.5
		box.size = boss_size

	# Position claws relative to body
	if left_claw:
		left_claw.size = Vector2(40, 40)
		left_claw.position = Vector2(boss_size.x * 0.5, -boss_size.y * 0.5 - 20)

	if right_claw:
		right_claw.size = Vector2(40, 40)
		right_claw.position = Vector2(boss_size.x * 0.5, boss_size.y * 0.5 - 20)

	if label != null:
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-boss_size.x * 0.5, -boss_size.y * 0.5)
		label.size = boss_size
		var label_settings := LabelSettings.new()
		label_settings.font = font
		label_settings.font_size = 24
		label_settings.font_color = text_color
		label.label_settings = label_settings
		# Counteract rotation for label? Maybe not needed if top down.
		label.rotation = -rotation

	if health_bar_back != null:
		health_bar_back.color = health_bar_back_color
		health_bar_back.position = Vector2(-boss_size.x * 0.5, boss_size.y * 0.5 + health_bar_offset)
		health_bar_back.size = Vector2(boss_size.x, health_bar_height)
	if health_bar_fill != null:
		health_bar_fill.color = health_bar_fill_color
		health_bar_fill.position = Vector2(-boss_size.x * 0.5, boss_size.y * 0.5 + health_bar_offset)
		health_bar_fill.size = Vector2(boss_size.x, health_bar_height)
	if shield_bar_fill != null:
		shield_bar_fill.color = shield_bar_fill_color
		shield_bar_fill.position = Vector2(-boss_size.x * 0.5, boss_size.y * 0.5 + health_bar_offset)
		shield_bar_fill.size = Vector2(boss_size.x, health_bar_height)

func _update_health_bar() -> void:
	if health_bar_fill != null:
		var health_percent := 0.0
		if max_health > 0.0:
			health_percent = current_health / max_health
		health_bar_fill.size = Vector2(boss_size.x * health_percent, health_bar_height)

	if shield_bar_fill != null:
		var shield_percent := 0.0
		if max_shield > 0.0:
			shield_percent = current_shield / max_shield
		shield_bar_fill.size = Vector2(boss_size.x * shield_percent, health_bar_height)

# Copied helper methods
func _get_world_bounds() -> Rect2:
	var arena_manager = get_tree().get_first_node_in_group("arena_manager")
	if arena_manager != null and arena_manager.has_method("get_bounds"):
		return arena_manager.get_bounds()
	if bounds_node != NodePath():
		var node := get_node_or_null(bounds_node)
		if node != null and node.has_method("get_bounds"):
			var local_bounds: Rect2 = node.get_bounds()
			return Rect2(local_bounds.position + node.global_position, local_bounds.size)
	return Rect2(Vector2.ZERO, get_viewport_rect().size)

func _find_boss_bar() -> Node:
	if health_bar_path != NodePath():
		return get_node_or_null(health_bar_path)
	return get_tree().get_first_node_in_group("boss_health_bar")

func _sync_boss_bar() -> void:
	if _boss_bar == null:
		_boss_bar = _find_boss_bar()
	if _boss_bar != null:
		if _boss_bar.has_method("update_boss_health"):
			if _boss_bar.has_method("update_boss_stats"):
				_boss_bar.update_boss_stats(self, current_health, max_health, current_shield, max_shield)
			else:
				_boss_bar.update_boss_health(self, current_health, max_health)
		elif _boss_bar.has_method("register_boss"):
			_boss_bar.register_boss(self)

func _resolve_collisions() -> void:
	# Basic soft collisions with other enemies could go here
	pass

func get_bounds_rect() -> Rect2:
	var half := boss_size * 0.5
	return Rect2(global_position - half, boss_size)

func _process(delta: float) -> void:
	# Keep label upright if we rotate the body
	if label:
		label.global_rotation = 0
	if health_bar_back:
		health_bar_back.global_rotation = 0
		health_bar_back.global_position = global_position + Vector2(-boss_size.x * 0.5, boss_size.y * 0.5 + health_bar_offset).rotated(rotation)
	if health_bar_fill:
		health_bar_fill.global_rotation = 0
		health_bar_fill.global_position = health_bar_back.global_position
	if shield_bar_fill:
		shield_bar_fill.global_rotation = 0
		shield_bar_fill.global_position = health_bar_back.global_position
