extends CharacterBody2D

@export var speed := 180.0
@export var explosion_damage := 2
@onready var area_2d = $Area2D
@export var prime_distance = 40
# 1. ADD THESE for the effect
@export var explosion_texture: Texture2D # Drag your explosion sprite here in Inspector
@export var explosion_color: Color = Color(1.0, 0.7, 0.3, 1.0) # Orange/Yellow glow

var player = null
var is_primed := false

func _ready():
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if player and not is_primed:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()
		
		# If we get close to player, start the fuse
		if global_position.distance_to(player.global_position) < prime_distance:
			start_explosion_sequence()

# --- THE IMMORTALITY / CHAIN REACTION LOGIC ---
func take_damage(amount: int):
	# Dagger hit just primes the fuse, it doesn't kill it
	if not is_primed:
		print("Boomkin hit! Priming...")
		start_explosion_sequence()

func start_explosion_sequence():
	if is_primed: return
	is_primed = true
	velocity = Vector2.ZERO # Stop moving when primed
	
	# Visual countdown (flashing red)
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3) # Flash 3 times
	tween.finished.connect(explode)

func explode():
	# 1. VISUALS (Circle Flash)
	var flash = Node2D.new()
	var script_path = "res://Scripts/ExplosionEffect.gd"
	if FileAccess.file_exists(script_path):
		flash.set_script(load(script_path))
		flash.radius = $Area2D/Radius.shape.radius
		get_parent().add_child(flash)
		flash.global_position = global_position
		var tween = get_parent().create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.2)
		tween.tween_callback(flash.queue_free)

	# 2. PARTICLES
	var particles = $ExplosionParticles 
	if particles:
		var global_pos = particles.global_position
		remove_child(particles)
		get_parent().add_child(particles)
		particles.global_position = global_pos
		particles.emitting = true
		get_tree().create_timer(1.5).timeout.connect(particles.queue_free)

	# 3. DAMAGE LOGIC
	var targets = area_2d.get_overlapping_bodies()
	
	for body in targets:
		if body == self: continue
		
		var health_node = body.get_node_or_null("Health")
		if not health_node: continue

		# --- TARGET: PLAYER (Directly modify health to bypass i-frames) ---
		if body.is_in_group("player"):
			if "current_health" in health_node:
				health_node.current_health -= 2
				print("Explosion forced 2 damage to Player. HP: ", health_node.current_health)
				
				# If your Health.gd has a function to update the heart UI, call it here
				if health_node.has_method("update_ui"):
					health_node.update_ui()
				
				# Manual check for player death since we bypassed take_damage
				if health_node.current_health <= 0 and health_node.has_method("die"):
					health_node.die()
			# --- TARGET: ENEMY ---
		elif body.is_in_group("enemy"):
			print("Detected Enemy: ", body.name) # Debug: See if Skitter is even detected
			
			if health_node:
				health_node.take_damage(50)
				print("Hit Health Node on ", body.name)
			
			# 2. Try calling take_damage on the Skitter body itself
			elif body.has_method("take_damage"):
				body.take_damage(50)
				print("Hit method on ", body.name)
				
			# 3. Last resort: Direct health subtraction (if Skitter has a health var)
			elif "health" in body:
				body.health -= 50
				print("Subtracted health variable directly from ", body.name)

		# 4. REMOVE PUMPKIN
		queue_free()
