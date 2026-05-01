extends CanvasLayer

# This points to the NEW name for the single heart
@onready var heart_piece = preload("res://UI/Hearts.tscn")
@onready var container = $HBoxContainer

func update_hearts(current_hp: float, max_hp: int):
	if not container: return
	
	for child in container.get_children():
		child.queue_free()
	
	# We divide max_hp by 2 because 2 points = 1 visual heart container
	for i in range(max_hp / 2):
		var h = heart_piece.instantiate()
		container.add_child(h)
		var sprite = h.find_child("AnimatedSprite2D")
		
		if sprite:
			# If index is 0, we need 2 points for FULL
			if current_hp >= (i + 1) * 2:
				sprite.play("full")
			# If we have at least 1 point more than the previous hearts
			elif current_hp >= (i * 2) + 1:
				sprite.play("half")
			else:
				sprite.play("empty")
