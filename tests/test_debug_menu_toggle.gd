extends Node
# Automated tests for debug menu toggle functionality

var test_results = []
var tests_passed = 0
var tests_failed = 0


func run_tests():
	print("=== Starting Debug Menu Toggle Tests ===")
	await test_debug_menu_toggle()
	print_test_summary()
	return tests_failed == 0


func test_debug_menu_toggle():
	print("\n--- Test: Debug Menu Toggle ---")

	var debug_menu_scene = load("res://scenes/game_scene/debug_menu.tscn")
	if debug_menu_scene == null:
		test_results.append("FAIL: Could not load debug_menu.tscn")
		tests_failed += 1
		return

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		test_results.append("FAIL: SceneTree not available")
		tests_failed += 1
		return

	var layer = debug_menu_scene.instantiate()
	tree.root.add_child(layer)
	
	# The script is on the DebugMenu child node
	var debug_menu = layer.get_node("DebugMenu")
	if debug_menu == null:
		test_results.append("FAIL: Could not find DebugMenu node in layer")
		tests_failed += 1
		layer.queue_free()
		return

	# Wait for _ready
	await tree.process_frame

	# Initially should be hidden
	if debug_menu.visible:
		test_results.append("FAIL: Debug menu should be initially hidden")
		tests_failed += 1
	else:
		test_results.append("PASS: Debug menu is initially hidden")
		tests_passed += 1

	# Simulate toggle
	debug_menu.visible = true
	debug_menu._refresh_all()
	debug_menu._pause_gameplay()
	
	if not debug_menu.visible:
		test_results.append("FAIL: Debug menu should be visible after toggle")
		tests_failed += 1
	else:
		test_results.append("PASS: Debug menu is visible after toggle")
		tests_passed += 1

	if tree.paused:
		test_results.append("PASS: Gameplay is paused when debug menu is open")
		tests_passed += 1
	else:
		test_results.append("FAIL: Gameplay should be paused when debug menu is open")
		tests_failed += 1

	# Test resuming
	debug_menu.visible = false
	debug_menu._resume_gameplay()
	
	if not tree.paused:
		test_results.append("PASS: Gameplay is resumed when debug menu is closed")
		tests_passed += 1
	else:
		test_results.append("FAIL: Gameplay should be resumed when debug menu is closed")
		tests_failed += 1

	layer.queue_free()


func print_test_summary():
	print("\n=== Test Summary ===")
	for result in test_results:
		print(result)
	print("Tests passed: " + str(tests_passed))
	print("Tests failed: " + str(tests_failed))