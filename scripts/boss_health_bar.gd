extends Control

@export var max_health: float = 200.0
@export var current_health: float = 200.0
@export var bar_color: Color = Color(0.9, 0.1, 0.1, 1)
@export var back_color: Color = Color(0.12, 0.12, 0.12, 0.85)
@export var outline_color: Color = Color(1, 1, 1, 1)
@export var outline_width: float = 2.0

var _boss_healths: Dictionary = {}


func _ready() -> void:
	add_to_group("boss_health_bar")
	queue_redraw()


func set_health(current: float, max_value: float) -> void:
	max_health = max_value
	current_health = clamp(current, 0.0, max_health)
	queue_redraw()


func register_boss(boss: Node) -> void:
	_update_boss_entry(boss, boss.current_health, boss.max_health)


func update_boss_health(boss: Node, current: float, max_value: float) -> void:
	_update_boss_entry(boss, current, max_value)


func unregister_boss(boss: Node) -> void:
	if boss == null:
		return
	_boss_healths.erase(boss.get_instance_id())
	_recalculate_totals()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, back_color, true)
	var percent := 0.0
	if max_health > 0.0:
		percent = current_health / max_health
	var fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * percent, size.y))
	draw_rect(fill_rect, bar_color, true)
	draw_rect(rect, outline_color, false, outline_width)


func _update_boss_entry(boss: Node, current: float, max_value: float) -> void:
	if boss == null:
		return
	_boss_healths[boss.get_instance_id()] = Vector2(current, max_value)
	_recalculate_totals()


func _recalculate_totals() -> void:
	var total_current := 0.0
	var total_max := 0.0
	for value in _boss_healths.values():
		total_current += value.x
		total_max += value.y
	set_health(total_current, total_max)
