extends Area2D

@export var speed := 200
var direction := Vector2.ZERO

func _physics_process(delta):
	global_position += direction * speed * delta

	# Optional: destroy if off-screen
	var vp = get_viewport_rect()
	if global_position.x < 0 or global_position.y < 0 \
	or global_position.x > vp.size.x or global_position.y > vp.size.y:
		queue_free()

func _on_body_entered(body):
	if body.name == "Player": # assumes your player node is named Player
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	
