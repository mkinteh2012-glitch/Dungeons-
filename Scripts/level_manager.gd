extends Node

@export_file("*.tscn") var next_level_path: String
signal level_completed # Define the signal here
signal transition_finished # Emitted when the new level is actually ready

func _ready():
	# Wait for the scene tree to settle
	await get_tree().process_frame
	
	var game_node = get_tree().current_scene
	
	# Connect to the win signal
	if game_node.has_signal("all_enemies_defeated"):
		if not game_node.all_enemies_defeated.is_connected(_on_objective_met):
			game_node.all_enemies_defeated.connect(_on_objective_met)
			print("LevelManager: Ready!")

func _on_objective_met():
	print("LevelManager: Objective met. Cleaning up...")
	
	# 1. Delay for the 'Victory' feel
	var music_node = get_tree().get_first_node_in_group("music_system")
	music_node.play_level_cleared()
	await get_tree().create_timer(4).timeout

	# 2. EMERGENCY CLEANUP
	# Manually kill enemies and bananas so their scripts stop running immediately
	for n in get_tree().get_nodes_in_group("enemy"): 
		n.queue_free()
	for n in get_tree().get_nodes_in_group("projectiles"): 
		n.queue_free()
	for n in get_tree().get_nodes_in_group("coin"): 
		n.queue_free()
	
	# 3. THE SWAP
	var current_scene = get_tree().current_scene
	
	if current_scene.has_method("load_new_level"):
		# If using a Master/Main script, it MUST handle the queue_free of the old level child
		current_scene.load_new_level(next_level_path)
	else:
		# If using Godot's built-in switcher, call_deferred is mandatory
		get_tree().call_deferred("change_scene_to_file", next_level_path)
		
	print("LevelManager: Transition started.")
	if music_node:
		music_node.reset_music_system()
