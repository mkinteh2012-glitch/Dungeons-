extends Area2D

var direction = Vector2.ZERO
var speed = 0.0
var damage = 10.0
var max_lifetime = 7.0
var is_launched := false
var is_max_power := false # Set this to true in the Player script on launch

func _ready():
	add_to_group("projectile")

func _physics_process(delta):
	if is_launched:
		global_position += direction * speed * delta
		rotation = direction.angle() + PI/2

func launch():
	is_launched = true
	if max_lifetime > 0:
		await get_tree().create_timer(max_lifetime).timeout
		queue_free()

func _on_body_entered(body):
	_handle_hit(body)

func _on_area_entered(area):
	_handle_hit(area)

func _handle_hit(victim):
	if not is_launched: return
	if victim.is_in_group("player"): return

	# 1. THE SEARCH LOGIC
	var current_node = victim
	var health_node = null
	
	for i in range(3):
		if current_node == null: break
		health_node = current_node.get_node_or_null("Health")
		if health_node: break
		current_node = current_node.get_parent()

	# 2. THE DAMAGE & JUICE LOGIC
	if health_node and health_node.has_method("take_damage"):
		print(is_max_power)
		health_node.take_damage(damage)
		
		if is_max_power:
			_trigger_impact_juice()
		
		queue_free()
		
	elif victim.has_method("take_damage"):
		victim.take_damage(damage)
		
		if is_max_power:
			
			_trigger_impact_juice()
			
		queue_free()
		
	elif victim.is_in_group("walls") or victim is TileMap  or victim is TileMapLayer:
		queue_free()

# Helper function to handle all the "Super Shot" effects
func _trigger_impact_juice():
	# A. PARTICLE LOGIC
	if has_node("GPUParticles2D"):
		var particles = $GPUParticles2D
		
		# Detach particles so they don't vanish when arrow is deleted
		var pos = particles.global_position
		remove_child(particles)
		get_tree().current_scene.add_child(particles)
		
		particles.global_position = pos
		particles.emitting = true
		
		# Clean up particles after they finish
		get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)
	
	# B. HIT PAUSE (Screen Freeze)
	# Assumes your player has the hit_pause function we discussed
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("hit_pause"):
		player.hit_pause(0.06)
