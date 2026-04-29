extends Area2D

var growth_speed = 600.0 # How fast the ring expands
var max_radius = 1500.0   # How big it gets before vanishing
var damage = 1

func _ready():
	# Start small
	scale = Vector2.ZERO

func _process(delta):
	# Make the ring expand
	var growth = growth_speed * delta
	scale += Vector2(growth, growth) * 0.01 # Adjust multiplier for feel
	
	# If it gets too big, delete it
	if scale.x * 100 > max_radius:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
		queue_free() 
	elif body.is_in_group("spark"):
		body.die()
			
