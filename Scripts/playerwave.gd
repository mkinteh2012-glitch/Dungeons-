extends Area2D

var damage = 5
var push_force = 800 # Increased for a bigger "pop" effect

func _ready():
	# 1. Start tiny
	scale = Vector2(0.1, 0.1)
	modulate.a = 1.0
	
	var tween = create_tween()
	# Use 'Ease Out' so it explodes fast then slows down as it reaches max size
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	
	# 2. THE BIG SCALE
	# Vector2(8, 8) is massive (8x original size)
	# Increased time to 0.5s so players can actually see the expansion
	tween.tween_property(self, "scale", Vector2(3.0, 3.0), 0.5)
	
	# 3. FADE OUT
	# Start fading slightly after it begins growing
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	queue_free()

func _on_body_entered(body):
	# Ignore player and walls (unless you want it to bounce off walls)
	if body.is_in_group("player") or body.is_in_group("walls"): 
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# 2. Push enemies back with the NEW push_force
	if "velocity" in body:
		var dir = (body.global_position - global_position).normalized()
		# Add the force to their current movement
		body.velocity += dir * push_force
		
		# If they have a knockback function, call that too
		if body.has_method("handle_hit"):
			body.handle_hit(global_position)
