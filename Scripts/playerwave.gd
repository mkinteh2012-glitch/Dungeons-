extends Area2D

var damage = 5
var push_force = 800 

func _ready():
	# --- NEW LEVEL SCALING ---
	var level = GameStats.ability_levels.get("wave", 1) # Default to 1 if not found
	
	# Increase damage: 5, 10, 15, 20...
	damage = 5 + (level * 4)
	
	# Increase push force: 800, 1000, 1200...
	push_force = 800 + (level * 20)
	
	# Calculate how big it gets: Level 1 = 3x, Level 5 = 5x
	var target_scale_value = 2.0 + (level * 0.5)
	var target_scale = Vector2(target_scale_value, target_scale_value)
	# --------------------------

	# 1. Start tiny
	scale = Vector2(0.1, 0.1)
	modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	
	# 2. Use our NEW calculated scale
	tween.tween_property(self, "scale", target_scale, 0.5)
	
	# 3. FADE OUT
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") or body.is_in_group("walls"): 
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	if "velocity" in body:
		var dir = (body.global_position - global_position).normalized()
		body.velocity += dir * push_force
		
		if body.has_method("handle_hit"):
			body.handle_hit(global_position)
