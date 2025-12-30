extends Node
# Automated tests for debug menu config persistence

var test_results = []
var tests_passed = 0
var tests_failed = 0


func run_tests():
	print("=== Starting Debug Menu Config Tests ===")
	test_boss_config_write_and_read()
	print_test_summary()
	return tests_failed == 0


func test_boss_config_write_and_read():
	print("\n--- Test 1: Boss Config Write/Read ---")

	var debug_menu_scene = load("res://scenes/game_scene/debug_menu.tscn")
	if debug_menu_scene == null:
		test_results.append("FAIL: Could not load debug_menu.tscn")
		tests_failed += 1
		return

	var instance = debug_menu_scene.instantiate()
	var test_path := "user://test_boss_config.cfg"
	instance.boss_config_path = test_path
	_cleanup_test_file(test_path)

	var values := {
		"max_health": 123.0,
		"speed": 456.0,
		"size": 78.0
	}

	instance._write_boss_config(values)
	var read_values: Dictionary = instance._read_boss_config()

	if read_values.is_empty():
		test_results.append("FAIL: Boss config read returned empty data")
		tests_failed += 1
	else:
		var max_health_ok = is_equal_approx(float(read_values.get("max_health", 0.0)), 123.0)
		var speed_ok = is_equal_approx(float(read_values.get("speed", 0.0)), 456.0)
		var size_ok = is_equal_approx(float(read_values.get("size", 0.0)), 78.0)

		if max_health_ok and speed_ok and size_ok:
			test_results.append("PASS: Boss config saved and loaded values correctly")
			tests_passed += 1
		else:
			test_results.append("FAIL: Boss config values did not match saved data")
			tests_failed += 1

	_cleanup_test_file(test_path)
	instance.queue_free()


func _cleanup_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var abs_path := ProjectSettings.globalize_path(path)
		DirAccess.remove_absolute(abs_path)


func print_test_summary():
	print("\n=== Test Summary ===")
	for result in test_results:
		print(result)
	print("Tests passed: " + str(tests_passed))
	print("Tests failed: " + str(tests_failed))
