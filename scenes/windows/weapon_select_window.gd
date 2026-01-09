extends Control

signal weapon_selected(weapon: WeaponData)

var _weapons: Array[WeaponData] = []
var _offered_known: WeaponData
var _offered_mystery: WeaponData


@onready var known_btn = $VBoxContainer/HBoxContainer/KnownWeaponButton
@onready var known_name = $VBoxContainer/HBoxContainer/KnownWeaponButton/VBox/Name
@onready var known_icon = $VBoxContainer/HBoxContainer/KnownWeaponButton/VBox/Icon

@onready var mystery_btn = $VBoxContainer/HBoxContainer/MysteryWeaponButton


func _ready() -> void:
	# Load all weapons
	var weapon_paths = [
		"res://resources/weapons/pistol.tres",
		"res://resources/weapons/shotgun.tres",
		"res://resources/weapons/sniper.tres"
	]

	for path in weapon_paths:
		var w = load(path)
		if w is WeaponData:
			_weapons.append(w)

	_setup_choices()

	known_btn.pressed.connect(_on_known_pressed)
	mystery_btn.pressed.connect(_on_mystery_pressed)

	# Make sure mouse is visible
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _setup_choices() -> void:
	if _weapons.is_empty():
		return

	# Pick a random "known" weapon
	_offered_known = _weapons[randi() % _weapons.size()]
	known_name.text = _offered_known.weapon_name
	if _offered_known.icon:
		known_icon.texture = _offered_known.icon

	# Pick a random "mystery" weapon (could be the same, that's fine for now)
	_offered_mystery = _weapons[randi() % _weapons.size()]


func _on_known_pressed() -> void:
	weapon_selected.emit(_offered_known)
	queue_free()


func _on_mystery_pressed() -> void:
	weapon_selected.emit(_offered_mystery)
	queue_free()
