extends Node2D

@export var bounds: Rect2 = Rect2(0, 0, 1280, 720):
	set(value):
		bounds = value
		queue_redraw()
		_update_player_bounds()
@export var line_color: Color = Color(0.3, 0.3, 0.4, 1)
@export var line_width: float = 2.0


func get_bounds() -> Rect2:
	return bounds


func _ready() -> void:
	line_color = GameColors.ARENA_LINE
	add_to_group("arena")
	queue_redraw()


func _draw() -> void:
	draw_rect(bounds, line_color, false, line_width)


func _update_player_bounds() -> void:
	# Update player bounds when arena bounds change
	if not is_inside_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player != null and is_instance_valid(player):
			if "bounds" in player:
				player.bounds = bounds
