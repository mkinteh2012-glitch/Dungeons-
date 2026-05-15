extends Area2D

var growth_speed = 600.0 
var max_radius = 1500.0   
var damage = 1

func _ready():
	# Start small
	scale = Vector2.ZERO

func _process(delta):

	var growth = growth_speed * delta
	scale += Vector2(growth, growth) * 0.01 
	

	if scale.x * 100 > max_radius:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free() 
	elif body.is_in_group("spark"):
		body.die()
			
