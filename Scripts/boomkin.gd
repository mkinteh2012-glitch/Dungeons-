extends CharacterBody2D

@export var speed := 120.0
@export var explosion_damage := 2
@export var prime_distance = 40

@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var area_2d = $Area2D
@onready var sprite = $AnimatedSprite2D

@export_group("Visual Effects")
@export var explosion_texture: Texture2D 
@export var explosion_color: Color = Color(1.0, 0.7, 0.3, 1.0)

var player: Node2D = null
var is_primed := false

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	
	#navigation setup
	nav_agent.path_desired_distance = 10.0 
	nav_agent.target_desired_distance = 10.0
	nav_agent.path_max_distance = 100.0 

	motion_mode = MOTION_MODE_FLOATING 
	wall_min_slide_angle = 0.0 
	
	makepath()

func _physics_process(_delta):
	if player and not is_primed:
	
		makepath()
		
	
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_path_pos)
		
		velocity = direction * speed
		

		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
			
		move_and_slide() 
		

		if global_position.distance_to(player.global_position) < prime_distance:
			start_explosion_sequence()

func makepath() -> void:
	if player:
		nav_agent.target_position = player.global_position


func take_damage(amount: int):
	if not is_primed:
		print("Boomkin hit! Priming...")
		start_explosion_sequence()

func start_explosion_sequence():
	if is_primed: return
	is_primed = true
	velocity = Vector2.ZERO 
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3) 
	tween.finished.connect(explode)

func explode():

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


	var particles = $ExplosionParticles 
	if particles:
		var global_pos = particles.global_position
		if particles.get_parent():
			particles.get_parent().remove_child(particles)
		get_parent().add_child(particles)
		particles.global_position = global_pos
		particles.emitting = true
		get_tree().create_timer(1.5).timeout.connect(particles.queue_free)


	var targets = area_2d.get_overlapping_bodies()
	for body in targets:
		if body == self: continue
		var health_node = body.get_node_or_null("Health")
		
		if body.is_in_group("player") and health_node:
			if "current_health" in health_node:
				health_node.current_health -= explosion_damage
				if health_node.has_method("update_ui"): health_node.update_ui()
				if health_node.current_health <= 0 and health_node.has_method("die"):
					health_node.die()
		
		elif body.is_in_group("enemy"):
			if body.has_method("start_explosion_sequence"): body.start_explosion_sequence()
			elif health_node: health_node.take_damage(50)
			elif body.has_method("take_damage"): body.take_damage(50)
	
	visible = false
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	
	if has_node("ExplodeSound"):
		$ExplodeSound.play()
		await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_timer_timeout():
	makepath()
