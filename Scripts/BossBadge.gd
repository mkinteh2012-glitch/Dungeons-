extends Area2D

@export var health: int = 25 # How many hits the badge takes
@export var badge_name: String = ""

func take_damage(amount: int):
	health -= amount
	
	# Visual feedback: Flash white when hit
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	
	if health <= 0:
		print(badge_name, " DESTROYED!")
		queue_free() # This removes the badge from the Boss's BadgesContainer
