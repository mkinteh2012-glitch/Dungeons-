extends Node2D
@export var level_name: String = "Crossfire"
@export var level_reward: int = 100
@export var level_difficulty: String = "Hard"
@onready var nav_region = $NavigationRegion2D # Make sure your node is named exactly this

func _ready():
	# We use call_deferred to wait until the level is fully 
	# loaded before we try to bake the floor.
	call_deferred("setup_navigation")

func setup_navigation():
	if nav_region:
		# This is the "Magic Button" that bakes the level automatically
		nav_region.bake_navigation_polygon()
		print("Level Pathfinding: Ready")
	else:
		print("Error: No NavigationRegion2D found in this level!")
