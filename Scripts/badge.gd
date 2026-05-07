extends Area2D

# Using a setter (set) ensures the animation changes the moment we assign the type
@export var badge_type: String = "Health":
	set(value):
		badge_type = value
		# We check if the node exists yet to avoid errors during initialization
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play(value)

func _ready():
	# This ensures it plays the correct animation if set via the Inspector
	$AnimatedSprite2D.play(badge_type)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Get the current level and max level to check if picking up is worth it
		var key = badge_type.to_lower()
		var current_lvl = GameStats.ability_levels.get(key, 0)
		var max_lvl = GameStats.max_levels.get(key, -1)
		
		# Optional: If already at max level, maybe just give coins?
		if max_lvl != -1 and current_lvl >= max_lvl:
			print("Already Max Level! Gained 50 coins instead.")
			GameStats.add_coins(50)
		else:
			# Use the new logic we wrote in Step 1
			GameStats.collect_badge_upgrade(key)
		
		# Refresh the player's stats (health, speed, etc)
		if body.has_method("update_stats"):
			body.update_stats()
			print("Player stats refreshed by: ", badge_type)
		
		queue_free()
		
