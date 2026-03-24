extends Area2D

@export var speed := 400.0
@export var damage := 1.0  # Added an export so you can change damage in the inspector
var direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# DEBUG: This will print every single thing the bullet touches
	for body in get_overlapping_bodies():
		print("I am touching: ", body.name)

func _on_body_entered(body: Node2D) -> void:
	# 1. Check if it's the player
	if body.is_in_group("player"):
		# 2. Call the take_damage function we're adding to your player script
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# 3. Destroy the projectile
		queue_free()
		
	elif body is TileMap:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
