extends Area2D

@export var speed := 275.0
@export var damage := 1.0 
var direction := Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:

	if body.is_in_group("player"):
	
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		
	
		queue_free()
		
	elif body is TileMapLayer or body is TileMap:
		queue_free() 
		
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
