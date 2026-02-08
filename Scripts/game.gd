extends Node2D

# Export to set which level loads
@export var level_scene: PackedScene
@onready var player = $Player

func _ready():
	# Instance the level
	var level_instance = level_scene.instantiate()
	add_child(level_instance)
	level_instance.name = "Test_level"

	# Find the PlayerSpawn marker in the level
	var spawn = level_instance.get_node("PlayerSpawn")
	
	# Move player to spawn position
	player.global_position = spawn.global_position
