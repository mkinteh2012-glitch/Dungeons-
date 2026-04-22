extends Node2D

signal all_enemies_defeated

@export var level_scene: PackedScene
@onready var player = $Player

var transitioning := false

func _ready():
	# Initial level load
	if level_scene:
		_setup_level(level_scene.instantiate())
	else:
		print("Error: No level_scene assigned!")

func _process(_delta):
	# Only check if we aren't already switching levels
	if not transitioning:
		check_level_completion()

func check_level_completion():
	# 1. Get all counts
	var enemies = get_tree().get_nodes_in_group("enemies").size()
	var enemy_alt = get_tree().get_nodes_in_group("enemy").size()
	var boss = get_tree().get_nodes_in_group("boss").size()
	var bosses = get_tree().get_nodes_in_group("bosses").size()
	

	# 3. The Logic
	# If any boss group has someone in it, we STOP.
	if boss > 0 or bosses > 0:
		return

	# If we reach here, no bosses were found. Now check minions.
	if enemies == 0 and enemy_alt == 0:
		if not transitioning:
			transitioning = true 
			print("Victory! All groups are empty. Signal emitted.")
			all_enemies_defeated.emit()
func load_new_level(path: String):
	if path == "" or path == null: 
		transitioning = false
		return
		
	# 1. Clear old level immediately
	var old_level = get_node_or_null("ActiveLevel")
	if old_level:
		old_level.name = "Level_Deleting" # Avoid name collision
		old_level.queue_free()
	
	# 2. Load new resource
	var new_res = load(path)
	if not new_res:
		transitioning = false
		return
		
	# 3. Instance and Setup
	var new_level = new_res.instantiate()
	_setup_level(new_level)

func _setup_level(level_instance):
	level_instance.name = "ActiveLevel"
	add_child(level_instance)
	
	# Reset Player Health
	var player_health = player.get_node_or_null("Health")
	if player_health:
		# Use the correct variable name from your Health script (health or current_health)
		if "health" in player_health: player_health.health = player_health.max_health
		elif "current_health" in player_health: player_health.current_health = player_health.max_health
	
	# Move Player to Spawn
	await get_tree().process_frame # Wait for spawn node to exist
	
	var spawn = level_instance.find_child("PlayerSpawn")
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.global_position = Vector2.ZERO
		
	# CRITICAL: Wait one more frame so enemies can register in their groups 
	# before we allow check_level_completion to run again!
	await get_tree().process_frame
	transitioning = false 
	print("Level Setup Complete.")
