extends Node
# Test runner for game over window functionality
# This script can be run directly to execute all tests

func _ready():
	print("Game Test Runner")
	call_deferred("_run_all_tests")


func _run_all_tests():
	print("Running automated tests...")
	
	var test_scripts = [
		preload("res://tests/test_game_over_window.gd").new(),
		preload("res://tests/test_main_game_cursor.gd").new(),
		preload("res://tests/test_debug_menu_config.gd").new(),
		preload("res://tests/test_debug_menu_toggle.gd").new(),
	]

	var success = true
	for test_script in test_scripts:
		success = test_script.run_tests() and success
	
	if success:
		print("\n🎉 All tests passed! Game over and cursor behavior look good.")
	else:
		print("\n❌ Some tests failed. Please review the output above.")
	
	# Exit after tests complete (useful for headless testing)
	get_tree().quit() if success else get_tree().quit(1)
