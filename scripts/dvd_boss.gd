extends Node2D

signal health_changed(current: float, max: float)
signal died

@export var max_health: float = 200.0
@export var current_health: float = 200.0
@export var size: float = 120.0
@export var speed: float = 320.0
@export var bounds_node: NodePath
@export var min_size: float = 30.0
@export var split_scale: float = 0.5
@export var split_offset: float = 28.0
@export var box_color: Color = Color(0.1, 0.1, 0.1, 1)
@export var text: String = "DVD"
@export var text_color: Color = Color(1, 1, 1, 1)
@export var font: Font = preload("res://assets/fonts/CozetteVectorBold.ttf")
@export var boss_scene: PackedScene
@export var health_bar_height: float = 8.0
@export var health_bar_back_color: Color = Color(0.1, 0.1, 0.1, 0.85)
@export var health_bar_fill_color: Color = Color(0.9, 0.2, 0.2, 1.0)
@export var health_bar_offset: float = 6.0
@export var health_bar_path: NodePath

var _boss_bar: Node = null
var _velocity: Vector2 = Vector2.ZERO
var _has_split: bool = false

@onready var box: ColorRect = $Box
@onready var label: Label = $Label
@onready var health_bar_back: ColorRect = $HealthBarBack
@onready var health_bar_fill: ColorRect = $HealthBarFill


func _ready() -> void:
	add_to_group("enemies")
	current_health = clamp(current_health, 0.0, max_health)
	_boss_bar = _find_boss_bar()
	call_deferred("_sync_boss_bar")
	if _velocity == Vector2.ZERO:
		_velocity = Vector2.RIGHT.rotated(randf() * TAU) * speed
	_apply_visuals()
	_update_health_bar()


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current_health = max(current_health - amount, 0.0)
	emit_signal("health_changed", current_health, max_health)
	_sync_boss_bar()
	_update_health_bar()
	if not _has_split and current_health <= max_health * 0.5:
		if size * split_scale >= min_size:
			_split()
			return
	if current_health <= 0.0:
		emit_signal("died")
		queue_free()


func get_bounds_rect() -> Rect2:
	var half := size * 0.5
	return Rect2(global_position - Vector2(half, half), Vector2(size, size))


func set_velocity(velocity: Vector2) -> void:
	_velocity = velocity


func _find_boss_bar() -> Node:
	if health_bar_path != NodePath():
		return get_node_or_null(health_bar_path)
	return get_tree().get_first_node_in_group("boss_health_bar")


func _sync_boss_bar() -> void:
	if _boss_bar == null:
		_boss_bar = _find_boss_bar()
	if _boss_bar != null:
		if _boss_bar.has_method("update_boss_health"):
			_boss_bar.update_boss_health(self, current_health, max_health)
		elif _boss_bar.has_method("register_boss"):
			_boss_bar.register_boss(self)
		elif _boss_bar.has_method("set_health"):
			_boss_bar.set_health(current_health, max_health)


func _exit_tree() -> void:
	if _boss_bar != null and _boss_bar.has_method("unregister_boss"):
		_boss_bar.unregister_boss(self)


func _physics_process(delta: float) -> void:
	var bounds := _get_world_bounds()
	if bounds.size == Vector2.ZERO:
		return
	global_position += _velocity * delta
	var half := size * 0.5
	var min_x := bounds.position.x + half
	var max_x := bounds.position.x + bounds.size.x - half
	var min_y := bounds.position.y + half
	var max_y := bounds.position.y + bounds.size.y - half
	if global_position.x < min_x:
		global_position.x = min_x
		_velocity.x = abs(_velocity.x)
	elif global_position.x > max_x:
		global_position.x = max_x
		_velocity.x = -abs(_velocity.x)
	if global_position.y < min_y:
		global_position.y = min_y
		_velocity.y = abs(_velocity.y)
	elif global_position.y > max_y:
		global_position.y = max_y
		_velocity.y = -abs(_velocity.y)
	_resolve_boss_collisions()


func _apply_visuals() -> void:
	if box != null:
		box.color = box_color
		box.position = Vector2(-size * 0.5, -size * 0.5)
		box.size = Vector2(size, size)
	if label != null:
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-size * 0.5, -size * 0.5)
		label.size = Vector2(size, size)
		var label_settings := LabelSettings.new()
		label_settings.font = font
		label_settings.font_size = int(clamp(size * 0.35, 12.0, 64.0))
		label_settings.font_color = text_color
		label.label_settings = label_settings
	if health_bar_back != null:
		health_bar_back.color = health_bar_back_color
		health_bar_back.position = Vector2(-size * 0.5, size * 0.5 + health_bar_offset)
		health_bar_back.size = Vector2(size, health_bar_height)
	if health_bar_fill != null:
		health_bar_fill.color = health_bar_fill_color
		health_bar_fill.position = Vector2(-size * 0.5, size * 0.5 + health_bar_offset)
		health_bar_fill.size = Vector2(size, health_bar_height)


func _update_health_bar() -> void:
	if health_bar_fill == null:
		return
	var percent := 0.0
	if max_health > 0.0:
		percent = current_health / max_health
	health_bar_fill.size = Vector2(size * percent, health_bar_height)


func _get_world_bounds() -> Rect2:
	if bounds_node != NodePath():
		var node := get_node_or_null(bounds_node)
		if node != null and node.has_method("get_bounds"):
			var local_bounds: Rect2 = node.get_bounds()
			return Rect2(local_bounds.position + node.global_position, local_bounds.size)
	return Rect2(Vector2.ZERO, get_viewport_rect().size)


func _split() -> void:
	_has_split = true
	if get_parent() == null:
		return
	var scene := boss_scene
	if scene == null:
		var scene_path := get_scene_file_path()
		if scene_path == "":
			return
		scene = load(scene_path)
		if scene == null:
			return
	var new_size := size * split_scale
	var new_max_health := max_health * split_scale
	var split_offsets := [
		Vector2(-split_offset, 0.0),
		Vector2(split_offset, 0.0),
	]
	for offset in split_offsets:
		var child := scene.instantiate()
		if child == null:
			continue
		child.size = new_size
		child.max_health = new_max_health
		child.current_health = new_max_health
		child.speed = speed
		child.bounds_node = bounds_node
		child.text = text
		child.text_color = text_color
		child.box_color = box_color
		child.font = font
		var new_velocity := Vector2.RIGHT.rotated(randf() * TAU) * speed
		child.set_velocity(new_velocity)
		get_parent().add_child(child)
		child.position = position + offset
	queue_free()


func _resolve_boss_collisions() -> void:
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		if not other.has_method("get_bounds_rect"):
			continue
		if get_instance_id() > other.get_instance_id():
			continue
		var other_rect: Rect2 = other.get_bounds_rect()
		var self_rect: Rect2 = get_bounds_rect()
		if not self_rect.intersects(other_rect):
			continue
		var overlap_x: float = (
			min(self_rect.position.x + self_rect.size.x, other_rect.position.x + other_rect.size.x)
			- max(self_rect.position.x, other_rect.position.x)
		)
		var overlap_y: float = (
			min(self_rect.position.y + self_rect.size.y, other_rect.position.y + other_rect.size.y)
			- max(self_rect.position.y, other_rect.position.y)
		)
		if overlap_x <= 0.0 or overlap_y <= 0.0:
			continue
		var normal := Vector2.ZERO
		if overlap_x < overlap_y:
			normal = Vector2.RIGHT if global_position.x < other.global_position.x else Vector2.LEFT
		else:
			normal = Vector2.DOWN if global_position.y < other.global_position.y else Vector2.UP
		var separation: Vector2 = normal * (min(overlap_x, overlap_y) * 0.5)
		global_position -= separation
		if other is Node2D:
			other.global_position += separation
		_velocity = _velocity.bounce(normal)
		_apply_other_bounce(other, -normal)


func _apply_other_bounce(other: Node, normal: Vector2) -> void:
	if other.has_method("set_velocity"):
		var other_velocity: Variant = other.get("_velocity")
		if other_velocity is Vector2:
			other.set_velocity(other_velocity.bounce(normal))
