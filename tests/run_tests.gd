extends Node
# Test runner for game over window functionality
# This script can be run directly to execute all tests

func _ready():
	print("Game Over Window Test Runner")
	print("Running automated tests...")
	
	var test_script = preload("res://tests/test_game_over_window.gd").new()
	var success = test_script.run_tests()
	
	if success:
		print("\n🎉 All tests passed! The game over window fixes are working correctly.")
	else:
		print("\n❌ Some tests failed. Please review the output above.")
	
	# Exit after tests complete (useful for headless testing)
	get_tree().quit() if success else get_tree().quit(1)