extends AnimatedSprite2D

func _ready():
	hide() # Hide until the enemy is hit

# We added 'current_hp' and 'max_hp' here so the function can use them
func update_health(current_hp: float, max_hp: float):
	show()
	
	# 1. Calculate percentage (0.0 to 1.0)
	var health_pct = clamp(current_hp / max_hp, 0.0, 1.0)
	
	# 2. Map percentage to 15 frames (0 to 14)
	var total_frames = 15
	
	# REVERSE MATH: 0 is Full, 14 is Empty
	var target_frame = (total_frames - 1) - round(health_pct * (total_frames - 1))
	
	frame = int(target_frame)
	
	# 3. Auto-hide if the enemy is dead
	if current_hp <= 0:
		hide()
