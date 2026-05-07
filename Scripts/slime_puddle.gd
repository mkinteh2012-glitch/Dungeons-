extends Area2D

@export var slow_amount: float = 100.0

func _ready():
	var tween = create_tween()
	tween.tween_interval(15.0)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# Isaac feel: reduce player speed while standing on it
		body.take_damage(1)
		queue_free()	
