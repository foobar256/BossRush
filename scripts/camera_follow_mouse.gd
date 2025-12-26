extends Camera2D

@export var bounds_node: NodePath
@export var player_node: NodePath
@export var bounds: Rect2 = Rect2(0, 0, 1280, 720)
@export var follow_speed: float = 6.0
@export var max_offset: float = 120.0

var _player: Node2D


func _ready() -> void:
	if bounds_node != NodePath():
		var node := get_node_or_null(bounds_node)
		if node != null and node.has_method("get_bounds"):
			bounds = node.get_bounds()
	if player_node != NodePath():
		_player = get_node_or_null(player_node) as Node2D


func _process(delta: float) -> void:
	var base_pos := global_position
	if _player != null:
		base_pos = _player.global_position

	var target := get_global_mouse_position()
	var offset := target - base_pos
	if offset.length() > max_offset:
		offset = offset.normalized() * max_offset
	target = base_pos + offset
	var min_pos := bounds.position
	var max_pos := bounds.position + bounds.size
	target.x = clamp(target.x, min_pos.x, max_pos.x)
	target.y = clamp(target.y, min_pos.y, max_pos.y)
	var t: float = minf(1.0, follow_speed * delta)
	global_position = global_position.lerp(target, t)
