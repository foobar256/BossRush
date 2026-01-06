extends Node

func run_tests() -> bool:
	print("Running Spawn Marker Tests...")
	return test_spawn_markers_created()

func test_spawn_markers_created() -> bool:
	var arena_manager_script = load("res://scripts/arena_manager.gd")
	var arena_manager = arena_manager_script.new()
	
	# Mock data
	arena_manager._current_arena_data = {
		"show_spawn_points": true,
		"boss_properties": {"size": 100.0}
	}
	arena_manager._player_spawn = Vector2(10, 10)
	var boss_spawns: Array[Vector2] = [Vector2(100, 100)]
	arena_manager._boss_spawns = boss_spawns
	
	# Need to add to tree to allow add_child to work properly if we want to find them by name
	# but we can also just check children
	arena_manager._create_spawn_markers()
	
	var player_marker = null
	var boss_marker = null
	
	for child in arena_manager.get_children():
		if child.name == "PlayerSpawnMarker":
			player_marker = child
		elif child.name == "BossSpawnMarker":
			boss_marker = child
			
	if player_marker == null:
		print("  - [FAIL] PlayerSpawnMarker not found")
		return false
	if boss_marker == null:
		print("  - [FAIL] BossSpawnMarker not found")
		return false
		
	if player_marker.position != Vector2(10, 10):
		print("  - [FAIL] Player marker at wrong position: ", player_marker.position)
		return false
		
	if player_marker.get("shape") != 0: # CIRCLE
		print("  - [FAIL] Player marker has wrong shape: ", player_marker.get("shape"))
		return false
		
	if boss_marker.get("marker_size") != Vector2(100, 100):
		print("  - [FAIL] Boss marker has wrong size: ", boss_marker.get("marker_size"))
		return false

	print("  - [PASS] Spawn markers created and configured correctly")
	return true