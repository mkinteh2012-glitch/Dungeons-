extends Node

# Drag your next level .tscn file into this slot in the Inspector!
@export_file("*.tscn") var next_level_path: String

func _ready():
	# Wait one frame to ensure the scene tree is fully populated
	await get_tree().process_frame
	
	var game_node = get_tree().current_scene
	
	if game_node.has_signal("all_enemies_defeated"):
		# Ensure we don't connect twice
		if not game_node.all_enemies_defeated.is_connected(_on_objective_met):
			game_node.all_enemies_defeated.connect(_on_objective_met)
			print("LevelManager: Connected to signal!")
	else:
		print("LevelManager Error: No signal found on ", game_node.name)

func _on_objective_met():
	print("LevelManager: Level Cleared! Preparing clean transition...")
	
	# 1. Give the player a moment to see the victory
	await get_tree().create_timer(1.5).timeout
	
	# 2. Safety: Stop all physics/input processing for the old scene 
	# This prevents Rory or Bullets from doing things during the transition
	var current_level = get_tree().current_scene
	current_level.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 3. Use deferred call to switch scenes. 
	# This tells Godot: "Finish this frame, delete everything, THEN load the new file."
	if current_level.has_method("load_new_level"):
		current_level.call_deferred("load_new_level", next_level_path)
	else:
		get_tree().call_deferred("change_scene_to_file", next_level_path)
