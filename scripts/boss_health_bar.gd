extends Control

@export var max_health: float = 200.0
@export var current_health: float = 200.0
@export var max_shield: float = 0.0
@export var current_shield: float = 0.0
@export var bar_color: Color = Color(0.8, 0.4, 0.4, 1)
@export var shield_color: Color = Color(0.4, 0.6, 0.8, 1)
@export var back_color: Color = Color(0.12, 0.12, 0.15, 0.85)
@export var outline_color: Color = Color(0.9, 0.86, 0.8, 1)
@export var outline_width: float = 2.0

var _boss_healths: Dictionary = {}


func _ready() -> void:
	bar_color = GameColors.HEALTH
	shield_color = GameColors.SHIELD
	back_color = GameColors.BACKGROUND
	back_color.a = 0.85
	outline_color = GameColors.TEXT
	add_to_group("boss_health_bar")
	queue_redraw()


func set_health(current: float, max_value: float) -> void:
	max_health = max_value
	current_health = clamp(current, 0.0, max_health)
	queue_redraw()


func set_stats(current_h: float, max_h: float, current_s: float, max_s: float) -> void:
	max_health = max_h
	current_health = clamp(current_h, 0.0, max_health)
	max_shield = max_s
	current_shield = clamp(current_s, 0.0, max_shield)
	queue_redraw()


func register_boss(boss: Node) -> void:
	var c_shield = boss.get("current_shield") if "current_shield" in boss else 0.0
	var m_shield = boss.get("max_shield") if "max_shield" in boss else 0.0
	_update_boss_entry(boss, boss.current_health, boss.max_health, c_shield, m_shield)


func update_boss_health(boss: Node, current: float, max_value: float) -> void:
	_update_boss_entry(boss, current, max_value, 0.0, 0.0)


func update_boss_stats(
	boss: Node, current_h: float, max_h: float, current_s: float, max_s: float
) -> void:
	_update_boss_entry(boss, current_h, max_h, current_s, max_s)


func unregister_boss(boss: Node) -> void:
	if boss == null:
		return
	_boss_healths.erase(boss.get_instance_id())
	_recalculate_totals()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, back_color, true)

	# Draw Health
	var health_percent := 0.0
	if max_health > 0.0:
		health_percent = current_health / max_health
	var health_fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * health_percent, size.y))
	draw_rect(health_fill_rect, bar_color, true)

	# Draw Shield on top (layered)
	if max_shield > 0.0:
		var shield_percent := current_shield / max_shield
		var shield_fill_rect := Rect2(Vector2.ZERO, Vector2(size.x * shield_percent, size.y))
		# Maybe make it slightly thinner or just overlay?
		# Overlaying with some transparency or different height is common.
		# Let's try simple overlay for now.
		draw_rect(shield_fill_rect, shield_color, true)

	draw_rect(rect, outline_color, false, outline_width)


func _update_boss_entry(
	boss: Node, current: float, max_value: float, c_shield: float = 0.0, m_shield: float = 0.0
) -> void:
	if boss == null:
		return
	_boss_healths[boss.get_instance_id()] = {
		"health": Vector2(current, max_value), "shield": Vector2(c_shield, m_shield)
	}
	_recalculate_totals()


func _recalculate_totals() -> void:
	var total_current_h := 0.0
	var total_max_h := 0.0
	var total_current_s := 0.0
	var total_max_s := 0.0

	for data in _boss_healths.values():
		var h = data["health"]
		var s = data["shield"]
		total_current_h += h.x
		total_max_h += h.y
		total_current_s += s.x
		total_max_s += s.y

	set_stats(total_current_h, total_max_h, total_current_s, total_max_s)
