extends Area2D

@export var growth_speed: float = 600.0 
@export var max_radius: float = 1500.0   
@export var damage: int = 1
@export var basestun: float = 3.0

func _ready() -> void:
	# Start small
	scale = Vector2.ZERO

func _process(delta: float) -> void:
	var growth = growth_speed * delta
	scale += Vector2(growth, growth) * 0.01 

	if scale.x * 100.0 > max_radius:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	elif body.is_in_group("spark"):
		if body.has_method("die"):
			body.die()
	elif body.is_in_group("enemy") or body.is_in_group("enemies"):
		if body.has_method("stun"):
			body.stun(basestun)
