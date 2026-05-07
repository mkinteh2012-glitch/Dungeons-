extends Node2D

@export var elec_scene: PackedScene 
@export var grid_width = 20          # Increased for full screen
@export var grid_height = 20         
@export var cell_size = Vector2(100, 100)
@export var move_speed = 120.0       

var current_phase = 0.0
var frequency = 1.5                  # Speed of the "scrolling" gaps

func _ready():
	# Make sure the grid itself isn't parented to the boss 
	# so it can move independently across the screen.
	top_level = true 
	_spawn_grid()

func _spawn_grid():
	for x in range(grid_width):
		for y in range(grid_height):
			if elec_scene:
				var elec = elec_scene.instantiate()
				add_child(elec)
				
				# Math to spread them out in a grid
				# This centers the grid on the TeslaGrid's global_position
				var x_pos = (x - (grid_width / 2.0)) * cell_size.x
				var y_pos = (y - (grid_height / 2.0)) * cell_size.y
				
				elec.position = Vector2(x_pos, y_pos)
				elec.scale = Vector2.ZERO # Hide initially

func _process(delta):
	# Move the WHOLE grid node
	position.x += move_speed * delta
	
	current_phase += frequency * delta
	
	var all_elec = get_children()
	for i in range(all_elec.size()):
		var elec = all_elec[i]
		
		# Create a sweeping "wave" of electricity
		# Columns further to the right are at a different point in the sine wave
		var column = int(i / grid_height)
		var wave = sin(current_phase + (column * 0.5))
		
		if wave > 0.4: # The threshold for "Active" electricity
			elec.scale = Vector2(1.5, 1.5)
			elec.modulate.a = 1.0
		else:
			elec.scale = Vector2.ZERO
			elec.modulate.a = 0.0
