extends Area2D

@export var heal_amount: int = 1

func _ready():
	# Make it "bob" up and down slightly so it looks fancy
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 4, 0.6)
	tween.tween_property(self, "position:y", position.y, 0.6)

func _on_body_entered(body):
	print("Heart touched by: ", body.name) # Check your output console!
	if body.is_in_group("player"):
		print("It's a player! Healing...")
		body.heal(heal_amount)
		queue_free()
