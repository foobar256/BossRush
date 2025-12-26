extends CanvasLayer

@export var svg_path: String = "res://assets/ui/crosshair.svg"
@onready var crosshair: Sprite2D = $CrosshairSprite


func _ready() -> void:
	add_to_group("crosshair_cursor")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var image := Image.new()
	var err := image.load(svg_path)
	if err == OK:
		crosshair.texture = ImageTexture.create_from_image(image)
	else:
		push_warning("Failed to load crosshair svg: %s" % svg_path)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	if visible:
		crosshair.position = get_viewport().get_mouse_position()


func set_enabled(enabled: bool) -> void:
	visible = enabled
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if enabled else Input.MOUSE_MODE_VISIBLE
