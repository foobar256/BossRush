extends Node
# Automated tests for cursor behavior on game over

var test_results = []
var tests_passed = 0
var tests_failed = 0


func run_tests():
	print("=== Starting Main Game Cursor Tests ===")

	test_game_over_cursor_state()

	print_test_summary()

	return tests_failed == 0


func test_game_over_cursor_state():
	print("\n--- Test 1: Game Over Cursor State ---")

	var main_game_scene = load("res://scenes/game_scene/main_game.tscn")
	if main_game_scene == null:
		test_results.append("FAIL: Could not load main_game.tscn")
		tests_failed += 1
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		test_results.append("FAIL: SceneTree not available for cursor test")
		tests_failed += 1
		return

	var instance = main_game_scene.instantiate()
	tree.root.add_child(instance)

	var crosshair = instance.get_node_or_null("Crosshair")
	var game_over_window = instance.get_node_or_null("GameOverWindow")

	if crosshair == null or game_over_window == null:
		test_results.append("FAIL: Missing Crosshair or GameOverWindow in main_game.tscn")
		tests_failed += 1
		instance.queue_free()
		return

	instance._on_player_died()

	if tree.paused == true:
		test_results.append("PASS: Game pauses on player death")
		tests_passed += 1
	else:
		test_results.append("FAIL: Game did not pause on player death")
		tests_failed += 1

	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		test_results.append("PASS: Mouse cursor is visible on game over")
		tests_passed += 1
	else:
		test_results.append("FAIL: Mouse cursor is not visible on game over")
		tests_failed += 1

	if crosshair.visible == false:
		test_results.append("PASS: Crosshair hides on game over")
		tests_passed += 1
	else:
		test_results.append("FAIL: Crosshair is still visible on game over")
		tests_failed += 1

	tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	instance.queue_free()


func print_test_summary():
	print("\n=== Test Summary ===")
	print("Tests Passed: " + str(tests_passed))
	print("Tests Failed: " + str(tests_failed))
	print("Total Tests: " + str(tests_passed + tests_failed))

	if tests_failed > 0:
		print("\nFailed Tests:")
		for result in test_results:
			if "FAIL" in result:
				print("  " + result)
	else:
		print("\nAll tests passed! ✅")

	print("===================")
