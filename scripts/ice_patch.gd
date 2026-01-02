extends Area2D

@export var friction_reduction: float = 0.05
@export var duration: float = 5.0
@export var fade_duration: float = 1.0

var _timer: float = 0.0
var _is_fading: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	_timer = duration
	
	# Initial scale animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0 and not _is_fading:
		_fade_out()
	
	if _is_fading:
		return
		
	# Check distance to players
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		var dist = global_position.distance_to(player.global_position)
		if dist < 40.0: # Ice patch radius roughly 40 units
			player.friction_multiplier = friction_reduction
		else:
			# Only reset if we were the one who set it (simplified for now)
			if player.friction_multiplier == friction_reduction:
				player.friction_multiplier = 1.0

func _fade_out() -> void:
	_is_fading = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, fade_duration)
	tween.finished.connect(queue_free)
