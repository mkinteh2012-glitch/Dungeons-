extends Node2D

func _process(_delta):
	# Only rotate if the bow is currently visible (active)
	if visible:
		look_at(get_global_mouse_position())
		
		# Optional: Flip the bow sprite if it's pointing left 
		# so it doesn't look upside down
		if get_global_mouse_position().x < global_position.x:
			scale.y = -1
		else:
			scale.y = 1
