extends CharacterBody2D

@export var speed := 150
@export var attack_cooldown := 0.5 
@export var lunge_force := 400.0  # How fast the lunge is
@export var lunge_duration := 0.15 # How long the lunge lasts

@onready var weapon_holder = $WeaponHolder
@onready var health = $Health
@onready var sprite = $AnimatedSprite2D

@export var dodge_speed := 600.0
@export var dodge_duration := 0.2
@export var dodge_cooldown := 0.8

var can_dodge := true
var is_dodging := false
var is_moving_last_frame := false

var dagger_scene = preload("res://Weapons/Dagger.tscn")
var current_weapon
var facing_direction := Vector2.RIGHT
var can_attack := true
var is_lunging := false

func _ready():
	# 1. Connect health
	health.died.connect(_on_died)
	
	# 2. Setup the dagger ONCE
	current_weapon = dagger_scene.instantiate()
	current_weapon.owner_player = self
	weapon_holder.add_child(current_weapon)
	

	current_weapon.position = Vector2( 12, 0)
	
	# 3. Setup the attack timer ONCE
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = attack_cooldown
	timer.one_shot = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)
	
func _physics_process(_delta):
	
	var is_moving_now = velocity.length() > 10.0 # Using 10.0 to avoid tiny jitters
	
	if is_moving_now and not is_moving_last_frame:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(0.8, 1.2), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	if not is_moving_now and is_moving_last_frame:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
	
	is_moving_last_frame = is_moving_now
	if is_dodging or is_lunging:
			move_and_slide()
			return

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		# 1. Normalize ensures diagonal speed isn't faster than straight speed
		facing_direction = input_vector.normalized()
		velocity = facing_direction * speed
		
		# 2. Animation logic
		sprite.play("Run")
		# Only flip if moving significantly left or right to avoid jitter
		if abs(input_vector.x) > 0.1:
			sprite.flip_h = input_vector.x < 0
		
		# 3. ROTATION (The "Walking" direction)
		if weapon_holder:
			# Use the angle of the movement vector
			# We add PI/2 (90 degrees) because your sprite faces DOWN by default
			weapon_holder.rotation = facing_direction.angle() + PI/2
	else:
		velocity = Vector2.ZERO
		sprite.play("Idle")

	move_and_slide()
	
func handle_hit(enemy_pos: Vector2):

	sprite.modulate = Color(10, 0, 0, 1)
	

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(4.0) 
	

	if enemy_pos != Vector2.ZERO:
		var knockback_direction = (global_position - enemy_pos).normalized()
		velocity = knockback_direction * 300.0 
		move_and_slide()
		
	
		is_dodging = true 
		await get_tree().create_timer(0.2).timeout
		is_dodging = false

	
	sprite.modulate = Color.WHITE
func dodge():
	can_dodge = false
	is_dodging = true
	
	# 1. Physics: Set the speed
	velocity = facing_direction * dodge_speed
	
	# 2. Visuals: Transparency
	sprite.modulate.a = 0.5 
	
	# 3. Invincibility
	if health:
		health.is_invincible = true
	
	# --- 4. THE GHOST TRAIL (Start this BEFORE the await) ---
	# We use a simple loop to spawn a few ghosts while the dodge happens
	for i in 5:
		if not is_dodging: break # Stop if the dodge ended early
		spawn_ghost()
		await get_tree().create_timer(0.04).timeout # Small gap between ghosts

	# 5. Wait for the dodge to finish
	await get_tree().create_timer(dodge_duration).timeout
	
	# 6. Reset everything
	is_dodging = false
	sprite.modulate.a = 1.0
	if health:
		health.is_invincible = false
		
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

# Helper function to keep dodge() clean
func spawn_ghost():
	var ghost = sprite.duplicate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	ghost.modulate = Color(1, 1, 1, 0.5) # Semi-transparent
	
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ghost.queue_free)
	
	if health:
		health.is_invincible = false
		
	# Wait for cooldown
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true
	
func _process(_delta):
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()
		
	if Input.is_action_just_pressed("dodge") and can_dodge and not is_dodging:
		dodge()

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if health:
	
		health.take_damage(amount, source_pos)
		print("Player hit for ", amount, " damage!")
	else:
		print("Warning: Player has no Health node assigned!")

func attack():
	can_attack = false
	is_lunging = true
	
	velocity = facing_direction * lunge_force
	
	current_weapon.attack(facing_direction)
	$AttackTimer.start()
	
	await get_tree().create_timer(lunge_duration).timeout
	is_lunging = false

func _on_attack_timer_timeout():
	can_attack = true

func _on_died():
	# Resets the scene when health hits 0
	get_tree().call_deferred("reload_current_scene")
