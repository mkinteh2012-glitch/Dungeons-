extends Node2D

@export var level_scene: PackedScene
@onready var player = $Player

# Add this variable so the script can track if it's already changing levels
var transitioning := false

func _ready():
	# 1. Instance the level
	if level_scene:
		var level_instance = level_scene.instantiate()
		add_child(level_instance)
		level_instance.name = "Test_level"

		# 2. Find the PlayerSpawn marker in the level
		# Using find_child is safer in case the node path changes slightly
		var spawn = level_instance.find_child("PlayerSpawn")
		
		if spawn:
			player.global_position = spawn.global_position
		else:
			print("Error: Could not find PlayerSpawn in the level!")
	else:
		print("Error: No level_scene assigned in the Inspector!")

func _process(_delta):
	# Don't check for enemies if we are already in the middle of a transition
	if not transitioning:
		check_enemies()

func check_enemies():
	# Get all nodes in the "enemies" group
	var enemies = get_tree().get_nodes_in_group("enemies")

	if enemies.size() == 0:
		print("All enemies dead!")
		transitioning = true
		start_transition()

func start_transition():
	# Wait a brief moment before reloading
	await get_tree().create_timer(0.5).timeout
	next_level()

func next_level():
	print("Reloading level...")
	get_tree().reload_current_scene()
