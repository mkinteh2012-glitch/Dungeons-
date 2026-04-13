extends Node2D

# This signal acts as the "Bridge" to your LevelManager
signal all_enemies_defeated

@export var level_scene: PackedScene
@onready var player = $Player

# This 'transitioning' variable is the "Lock" that stops the infinite loop
var transitioning := false

func _ready():
	if level_scene:
		var level_instance = level_scene.instantiate()
		add_child(level_instance)
		level_instance.name = "ActiveLevel"

		# Find the PlayerSpawn marker in the level
		var spawn = level_instance.find_child("PlayerSpawn")
		
		if spawn:
			player.global_position = spawn.global_position
		else:
			print("Warning: No PlayerSpawn found in level!")
			
		# Wait a tiny bit to make sure all enemies are registered in their groups
		await get_tree().process_frame
	else:
		print("Error: No level_scene assigned to Game node!")

func _process(_delta):
	# The 'if not transitioning' check is CRITICAL. 
	# It ensures the code inside only runs ONCE when the count hits zero.
	if not transitioning:
		check_level_completion()

func check_level_completion():
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	# If the list is empty, the player won
	if enemies.size() == 0:
		transitioning = true # Lock the gate so this doesn't run again
		
		print("All enemies dead! Sending signal to LevelManager...")
		all_enemies_defeated.emit()
func load_new_level(path: String):
	if path == "" or path == null: return
		
	transitioning = true
	
	# 1. Remove the old level
	var old_level = get_node_or_null("ActiveLevel")
	if old_level:
		old_level.queue_free()
	
	# 2. Instance the new level
	var new_level_resource = load(path)
	if not new_level_resource:
		print("ERROR: Could not load level path: ", path)
		return
		
	var new_level = new_level_resource.instantiate()
	new_level.name = "ActiveLevel"
	add_child(new_level)
	
	# 3. HEALTH RESET
	var player_health = player.get_node_or_null("Health")
	if player_health:
		player_health.current_health = player_health.max_health
		print("Player health restored!")
	
	# 4. Move Player to spawn
	await get_tree().process_frame
	
	# --- FIXED SECTION ---
	if is_instance_valid(new_level):
		var spawn = new_level.find_child("PlayerSpawn")
		
		if spawn:
			player.global_position = spawn.global_position
			print("Player moved to spawn.")
		else:
			print("ERROR: Could not find 'PlayerSpawn' in the new level!")
			player.global_position = Vector2.ZERO # Fallback
	else:
		print("ERROR: new_level is null or freed!")
	
	# 5. Unlock the transition gate so check_level_completion works again
	transitioning = false
