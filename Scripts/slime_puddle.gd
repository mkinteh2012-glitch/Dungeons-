extends Area2D

@export var slow_amount: float = 100.0

func _ready():
	# Visual entrance: Start tiny and grow
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK)
	
	# Life cycle: Stay for 3 seconds, then fade and die
	tween.tween_interval(3.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# Isaac feel: reduce player speed while standing on it
		if "speed" in body:
			body.speed -= slow_amount

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		if "speed" in body:
			body.speed += slow_amount
