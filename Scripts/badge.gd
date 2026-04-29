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
		# 1. Unlock the specific badge in GameStats
		GameStats.unlock_ability(badge_type.to_lower())
		
		# 2. Tell the player to refresh EVERYTHING
		if body.has_method("update_stats"):
			body.update_stats()
			print("Player stats refreshed by: ", badge_type)
		
		queue_free()
