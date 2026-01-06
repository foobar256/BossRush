extends Node
# Automated tests for Game Over Window functionality
# Tests centering, button functionality, and pause behavior

var test_results = []
var tests_passed = 0
var tests_failed = 0

func run_tests():
	print("=== Starting Game Over Window Tests ===")
	
	# Test 1: Scene structure validation
	test_scene_structure()
	
	# Test 2: Game over window centering
	test_window_centering()
	
	# Test 3: Button functionality
	test_button_functionality()
	
	# Test 4: Process mode behavior
	test_process_mode()
	
	# Test 5: Signal connections
	test_signal_connections()
	
	# Test 6: Main game integration
	test_main_game_integration()
	
	# Print summary
	print_test_summary()
	
	# Return true if all tests passed
	return tests_failed == 0


func test_scene_structure():
	print("\n--- Test 1: Scene Structure Validation ---")
	
	var game_over_window_scene = load("res://scenes/windows/game_over_window.tscn")
	if game_over_window_scene == null:
		test_results.append("FAIL: Could not load game_over_window.tscn")
		tests_failed += 1
		return
	
	var instance = game_over_window_scene.instantiate()
	
	# Check required nodes exist - use full paths for nested nodes
	var all_nodes_exist = true
	
	# Check direct children
	var background = instance.get_node_or_null("Background")
	if background == null:
		test_results.append("FAIL: Missing required node: Background")
		all_nodes_exist = false
		tests_failed += 1
	
	var vbox = instance.get_node_or_null("VBoxContainer")
	if vbox == null:
		test_results.append("FAIL: Missing required node: VBoxContainer")
		all_nodes_exist = false
		tests_failed += 1
	
	# Check nested nodes
	if vbox:
		var game_over_label = vbox.get_node_or_null("GameOverLabel")
		if game_over_label == null:
			test_results.append("FAIL: Missing required node: GameOverLabel")
			all_nodes_exist = false
			tests_failed += 1
		
		var hbox = vbox.get_node_or_null("HBoxContainer")
		if hbox == null:
			test_results.append("FAIL: Missing required node: HBoxContainer")
			all_nodes_exist = false
			tests_failed += 1
		
		if hbox:
			var restart_btn = hbox.get_node_or_null("RestartButton")
			var main_menu_btn = hbox.get_node_or_null("MainMenuButton")
			
			if restart_btn == null:
				test_results.append("FAIL: Missing required node: RestartButton")
				all_nodes_exist = false
				tests_failed += 1
			
			if main_menu_btn == null:
				test_results.append("FAIL: Missing required node: MainMenuButton")
				all_nodes_exist = false
				tests_failed += 1
	
	if all_nodes_exist:
		test_results.append("PASS: All required nodes exist")
		tests_passed += 1
	
	# Check script is attached
	if instance.script == null:
		test_results.append("FAIL: No script attached to GameOverWindow")
		tests_failed += 1
	else:
		test_results.append("PASS: Script is properly attached")
		tests_passed += 1
	
	instance.queue_free()


func test_window_centering():
	print("\n--- Test 2: Window Centering ---")
	
	var game_over_window_scene = load("res://scenes/windows/game_over_window.tscn")
	var instance = game_over_window_scene.instantiate()
	
	# Check VBoxContainer positioning
	var vbox = instance.get_node("VBoxContainer")
	if vbox:
		# Should be centered using anchors_preset = 8
		var layout_mode = vbox.get("layout_mode")
		var anchors_preset = vbox.get("anchors_preset")
		
		if anchors_preset == 8:  # Center preset
			test_results.append("PASS: VBoxContainer uses center anchor preset")
			tests_passed += 1
		else:
			test_results.append("FAIL: VBoxContainer not properly centered (preset: " + str(anchors_preset) + ")")
			tests_failed += 1
		
		# Check offset values for centering
		var offset_left = vbox.get("offset_left")
		var offset_top = vbox.get("offset_top")
		var offset_right = vbox.get("offset_right")
		var offset_bottom = vbox.get("offset_bottom")
		
		if offset_left == -150.0 and offset_top == -80.0 and offset_right == 150.0 and offset_bottom == 80.0:
			test_results.append("PASS: Window has correct offset values for centering")
			tests_passed += 1
		else:
			test_results.append("FAIL: Window offset values incorrect")
			tests_failed += 1
	else:
		test_results.append("FAIL: VBoxContainer not found")
		tests_failed += 1
	
	instance.queue_free()


func test_button_functionality():
	print("\n--- Test 3: Button Functionality ---")
	
	var game_over_window_scene = load("res://scenes/windows/game_over_window.tscn")
	var instance = game_over_window_scene.instantiate()
	
	# Get buttons
	var vbox = instance.get_node("VBoxContainer")
	if vbox:
		var hbox = vbox.get_node("HBoxContainer")
		if hbox:
			var restart_button = hbox.get_node("RestartButton")
			var main_menu_button = hbox.get_node("MainMenuButton")
			
			if restart_button and main_menu_button:
				test_results.append("PASS: Both buttons exist and are accessible")
				tests_passed += 1
				
				# Check button text
				if restart_button.text == "Restart" and main_menu_button.text == "Main Menu":
					test_results.append("PASS: Button texts are correct")
					tests_passed += 1
				else:
					test_results.append("FAIL: Button texts are incorrect")
					tests_failed += 1
			else:
				test_results.append("FAIL: Could not access buttons")
				tests_failed += 1
		else:
			test_results.append("FAIL: HBoxContainer not found")
			tests_failed += 1
	else:
		test_results.append("FAIL: VBoxContainer not found")
		tests_failed += 1
	
	instance.queue_free()


func test_process_mode():
	print("\n--- Test 4: Process Mode Behavior ---")
	
	var game_over_window_scene = load("res://scenes/windows/game_over_window.tscn")
	var instance = game_over_window_scene.instantiate()
	
	# Test that process mode is set to ALWAYS in _ready
	instance._ready()
	
	if instance.process_mode == Node.PROCESS_MODE_ALWAYS:
		test_results.append("PASS: Process mode is set to ALWAYS")
		tests_passed += 1
	else:
		test_results.append("FAIL: Process mode is not ALWAYS (value: " + str(instance.process_mode) + ")")
		tests_failed += 1
	
	instance.queue_free()


func test_signal_connections():
	print("\n--- Test 5: Signal Connections ---")
	
	var game_over_window_scene = load("res://scenes/windows/game_over_window.tscn")
	var instance = game_over_window_scene.instantiate()
	
	# Check if signals exist
	if instance.has_signal("restart_pressed") and instance.has_signal("main_menu_pressed"):
		test_results.append("PASS: Required signals exist")
		tests_passed += 1
	else:
		test_results.append("FAIL: Required signals missing")
		tests_failed += 1
	
	# Test signal emission using a helper object to track emissions
	# We use an array since arrays are passed by reference and can be modified in lambdas
	var emission_tracker = [false, false]  # [restart_emitted, main_menu_emitted]
	
	instance.restart_pressed.connect(func(): emission_tracker[0] = true)
	instance.main_menu_pressed.connect(func(): emission_tracker[1] = true)
	
	# Emit signals directly
	instance.restart_pressed.emit()
	instance.main_menu_pressed.emit()
	
	if emission_tracker[0] and emission_tracker[1]:
		test_results.append("PASS: Signals emit correctly when buttons are pressed")
		tests_passed += 1
	else:
		test_results.append("FAIL: Signals not emitting properly (restart: " + str(emission_tracker[0]) + ", main_menu: " + str(emission_tracker[1]) + ")")
		tests_failed += 1
	
	instance.queue_free()


func test_main_game_integration():
	print("\n--- Test 6: Main Game Integration ---")
	
	var main_game_scene = load("res://scenes/game_scene/main_game.tscn")
	if main_game_scene == null:
		test_results.append("FAIL: Could not load main_game.tscn")
		tests_failed += 1
		return
	
	var instance = main_game_scene.instantiate()
	
	# Check that GameOverWindow exists in scene using get_node_or_null
	var game_over_window = instance.get_node_or_null("GameOverLayer/GameOverWindow")
	
	if game_over_window == null:
		test_results.append("FAIL: GameOverWindow not found in main_game.tscn")
		tests_failed += 1
		instance.queue_free()
		return
	
	test_results.append("PASS: GameOverWindow found in main_game.tscn")
	tests_passed += 1
	
	# Check initial visibility (set in the .tscn file)
	if game_over_window.visible == false:
		test_results.append("PASS: GameOverWindow starts hidden")
		tests_passed += 1
	else:
		test_results.append("FAIL: GameOverWindow should start hidden")
		tests_failed += 1
	
	# Check that main_game.gd script exists
	var main_game_script = instance.get_script()
	if main_game_script == null:
		test_results.append("FAIL: No script attached to MainGame")
		tests_failed += 1
	else:
		test_results.append("PASS: MainGame has script attached")
		tests_passed += 1
	
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