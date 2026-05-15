extends Area2D

# Setter so liek it updates
@export var badge_type: String = "Health":
	set(value):
		badge_type = value
		
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play(value)

func _ready():

	$AnimatedSprite2D.play(badge_type)

func _on_body_entered(body):
	if body.is_in_group("player"):

		var key = badge_type.to_lower()
		var current_lvl = GameStats.ability_levels.get(key, 0)
		var max_lvl = GameStats.max_levels.get(key, -1)
		
		if max_lvl != -1 and current_lvl >= max_lvl:
			print("Already Max Level! Gained 50 coins instead.")
			GameStats.add_coins(50)
		else:

			GameStats.collect_badge_upgrade(key)
		

		if body.has_method("update_stats"):
			body.update_stats()
			print("Player stats refreshed by: ", badge_type)
		
		queue_free()
		
