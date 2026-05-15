extends Node2D

func _process(_delta):
	if visible:
		look_at(get_global_mouse_position())
		

		if get_global_mouse_position().x < global_position.x:
			scale.y = -1
		else:
			scale.y = 1
