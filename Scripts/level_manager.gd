extends Node

# Drag your next level .tscn file into this slot in the Inspector!
@export_file("*.tscn") var next_level_path: String

func _ready():
	# Wait for the Game scene to be fully ready
	await get_tree().process_frame
	
	# The 'Game' node is the root of the current scene
	var game_node = get_tree().current_scene
	
	# Check if the signal exists and connect it
	if game_node.has_signal("all_enemies_defeated"):
		game_node.all_enemies_defeated.connect(_on_objective_met)
		print("LevelManager: Successfully connected to Game signal!")
	else:
		print("LevelManager Error: Could not find 'all_enemies_defeated' signal on: ", game_node.name)

func _on_objective_met():
	print("LevelManager: Objective Met!")
	await get_tree().create_timer(1.5).timeout
	
	var game_node = get_tree().current_scene
	if game_node.has_method("load_new_level"):
		game_node.load_new_level(next_level_path)
	else:
		# Fallback if you aren't using the Master Game script
		get_tree().change_scene_to_file(next_level_path)
