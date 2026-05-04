extends Node

signal level_completed 

func _ready():
	await get_tree().process_frame
	var game_node = get_tree().current_scene
	
	if game_node.has_signal("all_enemies_defeated"):
		if not game_node.all_enemies_defeated.is_connected(_on_objective_met):
			game_node.all_enemies_defeated.connect(_on_objective_met)
			print("LevelManager: Linked!")

func _on_objective_met():
	print("LevelManager: Level Finished.")
	
	# 1. Victory delay
	var music_node = get_tree().get_first_node_in_group("music_system")
	if music_node:
		music_node.play_level_cleared()
	
	await get_tree().create_timer(4.0).timeout

	# 2. Add Money and Progress BEFORE cleanup
	# We look at the root of the current scene (Game.tscn) to find the ActiveLevel
	var game_scene = get_tree().current_scene
	var active_level = game_scene.get_node_or_null("ActiveLevel")
	
	if active_level:
		var reward = active_level.get("level_reward")
		if reward == null: reward = 0 # Failsafe if variable is missing
		
		# Use the correct math += and the correct Global variable
		GameStats.coins += reward
		Global.levels_completed += 1 
		print("Paid player: ", reward, ". Total Gold: ", GameStats.coins)
	else:
		# If it can't find 'ActiveLevel', it might just be the parent
		# Let's try to check the parent node just in case
		var reward = get_parent().get("level_reward")
		if reward:
			Global.total_gold += reward
			Global.levels_completed += 1
	
	# 3. Cleanup
	var groups_to_clear = ["enemy", "projectiles", "coin", "loot"]
	for group in groups_to_clear:
		for n in get_tree().get_nodes_in_group(group):
			n.queue_free()
	
	# 4. Redirect
	get_tree().call_deferred("change_scene_to_file", "res://UI/LevelSelectMenu.tscn")
	
	if music_node:
		music_node.reset_music_system()
