extends CharacterBody2D

@export var speed_walk := 60.0 
@export var speed_roll := 450.0 
@export var attack_range := 180.0
@export var roll_duration := 4.0
@export var roll_cooldown := 5.0 
@export var banana_scene: PackedScene = preload("res://Sprites/Projectile/banana.tscn")

@onready var anim = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

enum State { WALKING, TRANSITIONING, ROLLING, COOLDOWN, THROWING, MOVING_TO_CENTER }
var current_state = State.WALKING
var roll_direction := Vector2.ZERO
var can_damage_player := true 

func _physics_process(delta):
	match current_state:
		State.WALKING:
			move_logic(speed_walk, true)
			if player and global_position.distance_to(player.global_position) < attack_range:
				choose_attack()
			move_and_slide()

		State.MOVING_TO_CENTER:
			# Move specifically to 0,0
			var center_dir = global_position.direction_to(Vector2.ZERO)
			velocity = center_dir * speed_walk * 1.5 # Move a bit faster to get there
			
			if global_position.distance_to(Vector2.ZERO) < 10.0:
				velocity = Vector2.ZERO
				execute_banana_throw() # Start the telegraph + throw
			move_and_slide()

		State.COOLDOWN:
			move_logic(speed_walk * 1.2, false) # Flee from player
			move_and_slide()

		State.ROLLING:
			anim.play("ball")
			anim.rotation_degrees += 30
			var collision = move_and_collide(roll_direction * speed_roll * delta)
			if collision:
				handle_roll_collision(collision)

func move_logic(speed, toward_player):
	if player:
		var target_pos = player.global_position if toward_player else player.global_position
		var dir = global_position.direction_to(target_pos)
		var final_dir = dir if toward_player else -dir
		velocity = final_dir * speed
		if velocity.x != 0: anim.flip_h = velocity.x < 0
		anim.play("walk")

func choose_attack():
	if randf() > 0.5:
		start_rollout()
	else:
		current_state = State.MOVING_TO_CENTER

func execute_banana_throw():
	current_state = State.THROWING
	
	# --- VISUAL TELEGRAPH (INDICATOR) ---
	# Turn Rory slightly red and shake him so the player knows to get ready
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.RED, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3) # Shakes/Flashes 3 times
	
	await tween.finished
	
	# --- THE ATTACK ---
	for i in range(3):
		if banana_scene and player:
			var b = banana_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			b.direction = global_position.direction_to(player.global_position).rotated(randf_range(-0.3, 0.3))
		await get_tree().create_timer(0.2).timeout
	
	enter_cooldown()

func start_rollout():
	current_state = State.TRANSITIONING
	anim.play("transition")
	await anim.animation_finished 
	if player:
		roll_direction = global_position.direction_to(player.global_position)
		current_state = State.ROLLING
		await get_tree().create_timer(roll_duration).timeout
		if current_state == State.ROLLING: enter_cooldown()

func enter_cooldown():
	anim.modulate = Color.WHITE # Ensure he isn't red anymore
	anim.rotation_degrees = 0
	current_state = State.COOLDOWN
	await get_tree().create_timer(roll_cooldown).timeout
	current_state = State.WALKING

func handle_roll_collision(collision):
	var target = collision.get_collider()
	if target.is_in_group("player") and can_damage_player:
		target.take_damage(1, global_position)
		can_damage_player = false
		get_tree().create_timer(0.8).timeout.connect(func(): can_damage_player = true)
	roll_direction = roll_direction.bounce(collision.get_normal()).rotated(randf_range(-0.4, 0.4))
	global_position += roll_direction * 3.0
