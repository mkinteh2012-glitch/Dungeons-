extends Area2D

@export var speed := 400.0
var direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	# This moves the projectile forward
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# body.take_damage(10) # Replace with your player damage logic
		queue_free()
	elif body is TileMap:
		queue_free()

# Helps performance by deleting bullets that miss
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
