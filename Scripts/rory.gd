extends CharacterBody2D

@export var speed_walk := 60.0 
@export var speed_roll := 450.0 
@export var attack_range := 180.0
@export var roll_duration := 7.6
@export var roll_cooldown := 9.0	
@export var banana_scene: PackedScene


@onready var anim = $AnimatedSprite2D
@onready var player = get_tree().get_first_node_in_group("player")

@export var battle_start_delay := 4.5 # How long he stays still
var is_active := false # The "lock" that keeps him still

enum State { WALKING, TRANSITIONING, ROLLING, COOLDOWN, THROWING, MOVING_TO_CENTER }
var current_state = State.WALKING
var roll_direction := Vector2.ZERO
var can_damage_player := true 
var move_timer := 0.0 # Prevents getting stuck walking to center

func _ready():
	is_active = false
	velocity = Vector2.ZERO
	anim.play("walk")
	anim.stop() # Freeze him on the first frame of walk
	
	# Wait for the intro music/delay
	await get_tree().create_timer(battle_start_delay).timeout
	
	is_active = true
	print("Rory: Battle Start!")

func _physics_process(delta):
	if not is_active:
		return
	match current_state:
		State.WALKING:
			move_logic(speed_walk, true)
			if player and global_position.distance_to(player.global_position) < attack_range:
				choose_attack()
			move_and_slide()

		State.MOVING_TO_CENTER:
			move_timer += delta
			var center_pos = Vector2.ZERO # Change this if your center isn't 0,0
			var center_dir = global_position.direction_to(center_pos)
			velocity = center_dir * speed_walk * 1.5
			
			# If reached center OR stuck for 2 seconds, just throw
			if global_position.distance_to(center_pos) < 15.0 or move_timer > 2.0:
				move_timer = 0.0
				velocity = Vector2.ZERO
				await get_tree().create_timer(2.5).timeout
				execute_banana_throw()
			move_and_slide()

		State.COOLDOWN:
			move_logic(speed_walk * 1.2, false) # Flee from player
			move_and_slide()

		State.ROLLING:
			anim.play("ball")
			anim.rotation_degrees += 30
			var collision = move_and_collide(roll_direction * speed_roll * delta)
			if collision:
				var cam = get_viewport().get_camera_2d()
				if cam and cam.has_method("apply_shake"):
					cam.apply_shake(2.0)
				handle_roll_collision(collision)

func move_logic(speed, toward_player):
	if player:
		var dir = global_position.direction_to(player.global_position)
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
	if current_state != State.MOVING_TO_CENTER: return
	current_state = State.THROWING
	
	# Telegraph: Flash Red
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.RED, 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3)
	await tween.finished
	
	if not is_inside_tree(): return # Safety check
	
	

	# Throw 3 bananas
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
	
	# 1. Play the transition animation (turning into a ball)
	anim.play("transition")
	await anim.animation_finished 
	
	# --- START 5-SECOND CHARGE UP ---
	# Parallel allows us to scale and modulate at the same time
	var charge_tween = create_tween().set_parallel(true)
	
	# SHAKE LOGIC: 0.1s squash + 0.1s stretch = 0.2s per loop. 
	# 25 loops = 5 seconds total.
	charge_tween.tween_property(anim, "scale", Vector2(1.2, 0.8), 0.1).set_trans(Tween.TRANS_SINE)
	charge_tween.chain().tween_property(anim, "scale", Vector2(0.8, 1.2), 0.1)
	charge_tween.set_loops(25) 
	
	# GLOW LOGIC: Turn him orange/red over the full 5 seconds
	var color_tween = create_tween()
	color_tween.tween_property(anim, "modulate", Color(4, 1, 0), 5.0) # Intense Orange Glow
	
	# TRIGGER PIKMIN MUSIC: "Preparing an Attack"
	# Wait exactly 5 seconds for the charge to build
	await get_tree().create_timer(5.0).timeout
	# --- END CHARGE UP ---

	if player:
		# Reset visuals for the launch
		anim.modulate = Color.WHITE
		anim.scale = Vector2.ONE
			
		roll_direction = global_position.direction_to(player.global_position)
		current_state = State.ROLLING
		
		# How long he stays in the ROLLING state
		await get_tree().create_timer(roll_duration).timeout
		if current_state == State.ROLLING: 
			enter_cooldown()

func enter_cooldown():
	anim.modulate = Color.WHITE
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
	
	# Pinball bounce with nudge to prevent sticking
	roll_direction = roll_direction.bounce(collision.get_normal()).rotated(randf_range(-0.4, 0.4))
	global_position += roll_direction * 3.0
