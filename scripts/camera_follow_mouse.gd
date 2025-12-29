extends Camera2D

@export var player_node: NodePath
@export var bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export var follow_speed: float = 6.0
@export var max_offset: float = 120.0
@export var use_mouse_offset: bool = false

var _player: Node2D
var _arena_manager: Node2D


func _ready() -> void:
	# Find arena manager
	_arena_manager = get_tree().get_first_node_in_group("arena_manager")
	if _arena_manager == null:
		# Try to find it by name
		var root = get_tree().current_scene
		if root != null:
			_arena_manager = root.get_node_or_null("ArenaManager")

	# Get bounds from arena manager if available
	if _arena_manager != null and _arena_manager.has_method("get_bounds"):
		bounds = _arena_manager.get_bounds()

	if player_node != NodePath():
		_player = get_node_or_null(player_node) as Node2D


func _process(delta: float) -> void:
	var base_pos := global_position
	if _player != null:
		base_pos = _player.global_position

	var target := base_pos
	if use_mouse_offset:
		var mouse_pos := get_global_mouse_position()
		var offset := mouse_pos - base_pos
		if offset.length() > max_offset:
			offset = offset.normalized() * max_offset
		target = base_pos + offset
	var min_pos := bounds.position
	var max_pos := bounds.position + bounds.size
	target.x = clamp(target.x, min_pos.x, max_pos.x)
	target.y = clamp(target.y, min_pos.y, max_pos.y)
	var t: float = minf(1.0, follow_speed * delta)
	global_position = global_position.lerp(target, t)
