extends CharacterBody2D


var charge_time = 0.0
var charging_arrow_instance = null
signal coin_collected
@export var max_charge = 2.0
@export var min_speed = 200.0
@export var max_speed = 600.0
@export var speed := 150
@export var attack_cooldown := 0.5 
@export var lunge_force := 400.0  # How fast the lunge is
@export var lunge_duration := 0.15 # How long the lunge lasts
var has_bow_equipped = false # Starts with Dagger by default
@export var arrow_scene: PackedScene
@onready var weapon_holder = $WeaponHolder
@onready var health = $Health
@onready var sprite = $AnimatedSprite2D
var can_shoot = true
@export var shoot_speed = 0.25 # Seconds between shots
@export var dodge_speed := 600.0
@export var dodge_duration := 0.2
@export var dodge_cooldown := 0.8

var is_weakened: bool = false
var can_dodge := true
var is_dodging := false
var is_moving_last_frame := false

@export var dagger_scene: PackedScene
@export var bow_scene: PackedScene

var current_dagger = null
var current_bow = null

var current_weapon
var facing_direction := Vector2.RIGHT
var can_attack := true
var is_lunging := false

func _ready():
	# 1. Connect health
	health.died.connect(_on_died)
	
	# 2. Setup BOTH weapons
	# Instantiate Dagger
	current_dagger = dagger_scene.instantiate()
	current_dagger.owner_player = self
	weapon_holder.add_child(current_dagger)
	current_dagger.position = Vector2(12, 0)
	
	# Instantiate Bow (using the bow_scene you exported)
	current_bow = bow_scene.instantiate()
	# If your bow needs an owner_player reference too:
	if "owner_player" in current_bow:
		current_bow.owner_player = self
	weapon_holder.add_child(current_bow)
	current_bow.position = Vector2(0, 0)
	
	# 3. Initial Visibility State
	# Start with dagger visible, bow hidden
	has_bow_equipped = false
	current_dagger.visible = true
	current_bow.visible = false
	
	# 4. Setup the attack timer
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
			# ONLY rotate the holder automatically if we are using the dagger
			# This lets the Bow handle its own mouse-aiming logic
			if weapon_holder and not has_bow_equipped:
				weapon_holder.rotation = facing_direction.angle() + PI/2
			else:
				weapon_holder.rotation = 0

	else:
		velocity = Vector2.ZERO
		sprite.play("Idle")

	move_and_slide()
	
		# --- FORCE PUSH ENEMIES ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var target = collision.get_collider()
		
		if target.is_in_group("enemy") and not target.is_in_group("spawner") and not target.is_in_group("boss"):
			# Instead of just adding velocity, we 'teleport' them slightly
			# away so they don't block the player's path
			var push_dir = collision.get_normal() * -1.0
			target.global_position += push_dir * 2.0 # Tiny 'nudge' out of the way
	
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

	if is_weakened:
		sprite.modulate = Color(0.7, 0.2, 0.9, 1.0) # Stay Purple
	else:
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
	
func _process(delta):
	# 1. Weapon Logic
	if has_bow_equipped:
		_handle_bow_logic(delta)
	else:
		_handle_dagger_logic()
	
	# 2. Movement & Utility Logic
	if Input.is_action_just_pressed("switch_weapon"):
		_switch_weapon()

	if Input.is_action_just_pressed("dodge") and can_dodge and not is_dodging:
		dodge()

# Helper function to keep _process clean
func _handle_bow_logic(delta):
	if not can_shoot: return
	
	var bow_sprite = current_bow.get_node("AnimatedSprite2D")
	
	# 1. START CHARGING
	if Input.is_action_just_pressed("attack"):
		charging_arrow_instance = arrow_scene.instantiate()
		get_tree().current_scene.add_child(charging_arrow_instance)
		bow_sprite.play("charge")

	# 2. HOLDING CHARGE
	if Input.is_action_pressed("attack"):
		if is_instance_valid(charging_arrow_instance):
			charge_time += delta
			charge_time = min(charge_time, max_charge)
			
			# Stick arrow to muzzle
			var muzzle = current_bow.get_node("Muzzle")
			charging_arrow_instance.global_position = muzzle.global_position
			charging_arrow_instance.global_rotation = current_bow.global_rotation + PI/2
			
			# Visual frame syncing
			var frame_count = bow_sprite.sprite_frames.get_frame_count("charge")
			var target_frame = int((charge_time / max_charge) * (frame_count - 1))
			bow_sprite.frame = target_frame
			bow_sprite.pause() 

	# 3. RELEASE / LAUNCH (The Fix is here!)
	if Input.is_action_just_released("attack"):
		if is_instance_valid(charging_arrow_instance):
			bow_sprite.play("release")
			
			var charge_pct = clamp(charge_time / max_charge, 0.0, 1.0)
			
			# --- APPLY ALL STATS TO THE ARROW ---
			charging_arrow_instance.speed = lerp(min_speed, max_speed, charge_pct)
			charging_arrow_instance.damage = 20.0 + (50.0 * charge_pct) # Now it scales!
			charging_arrow_instance.max_lifetime = lerp(0.5, 2.0, charge_pct)
			charging_arrow_instance.direction = Vector2.RIGHT.rotated(current_bow.global_rotation)
			
			# Handle Super Shot visuals
			if charge_pct >= 1.0:
				charging_arrow_instance.is_max_power = true
				charging_arrow_instance.modulate = Color(2.0, 2.0, 2.0)
				charging_arrow_instance.scale = Vector2(1.2, 1.2)
			
			# Launch it
			if charging_arrow_instance.has_method("launch"):
				charging_arrow_instance.launch()
			
			# Clean up references
			charging_arrow_instance = null
			charge_time = 0.0
			_start_shoot_cooldown()

func _start_shoot_cooldown():
	can_shoot = false
	await get_tree().create_timer(shoot_speed).timeout
	can_shoot = true

func _handle_dagger_logic():
	if Input.is_action_just_pressed("attack"):
		_perform_dagger_stab()

func _switch_weapon():
	has_bow_equipped = !has_bow_equipped
	charge_time = 0.0 # Reset charge
	
	# This part actually makes them disappear/reappear
	if current_dagger and current_bow:
		current_dagger.visible = !has_bow_equipped
		current_bow.visible = has_bow_equipped
		
		# Optional: Debug check to see if code is running
		if has_bow_equipped:
			print("Visuals: Bow Shown")
		else:
			print("Visuals: Dagger Shown")
	else:
		print("Error: Weapons not found in weapon_holder!")

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if health:
	
		health.take_damage(amount, source_pos)
		print("Player hit for ", amount, " damage!")
	else:
		print("Warning: Player has no Health node assigned!")

func _perform_dagger_stab():
	# Use the variable you assigned in _ready()
	if current_dagger != null:
		current_dagger.attack(facing_direction)
	else:
		print("Error: Dagger is missing!")

func _on_attack_timer_timeout():
	can_attack = true
	
func apply_weakness(duration: float):
	# --- THE FIX ---
	# If we are already weakened, IGNORE any new hits from Vex
	if is_weakened:
		return 
	
	is_weakened = true
	sprite.modulate = Color(0.7, 0.2, 0.9, 1.0) # Purple
	
	# Simple countdown loop
	for i in range(duration, 0, -1):
		print("DEBUG: Weakness ending in... ", i)
		await get_tree().create_timer(1.0).timeout
	
	# Reset after the first timer finishes
	is_weakened = false
	sprite.modulate = Color.WHITE
	print("DEBUG: Weakness GONE")

func _on_died():
	print("Player has died!")
	
	# 1. Play the Game Over sound
	if has_node("GameOverSound"):
		$GameOverSound.play()
	
	# 2. Stop player movement and hide them
	set_physics_process(false) # Stops the FootstepController too!
	visible = false
	
	# 3. Disable collisions so enemies stop attacking the "ghost"
	$CollisionShape2D.set_deferred("disabled", true)
	
	# 4. Wait for the sound to finish a bit, then restart or show UI
	await get_tree().create_timer(1.5).timeout
	restart_game()

func restart_game():
	# For now, we just reload the scene
	get_tree().reload_current_scene()
	
func _shoot_arrow():
	can_shoot = false
	var arrow = arrow_scene.instantiate()
	
	# 1. Calculate direction and power
	var dir = (get_global_mouse_position() - global_position).normalized()
	var charge_pct = charge_time / max_charge
	if charge_pct > 1:
		charge_pct = 1
	
	# 2. Apply stats to the arrow instance
	arrow.direction = dir
	arrow.speed = lerp(min_speed, max_speed, charge_pct)
	arrow.damage = 10 + (10 * charge_pct)
	arrow.max_lifetime = arrow.max_lifetime
	
	
	# 3. Handle 100% Power (Super Shot)
	if charge_pct >= 1.0:
		arrow.is_max_power = true
		# Make the arrow glow or look more intense
		arrow.modulate = Color(2.0, 2.0, 2.0) 
		# Optional: make the super arrow slightly larger
		arrow.scale = Vector2(1.2, 1.2)
	
	# 4. Position and Rotation
	# If your bow has a 'Muzzle' Marker2D, use that position instead
	arrow.global_position = global_position
	
	# 5. Spawn and Launch
	get_tree().current_scene.add_child(arrow)
	arrow.launch() # Ensure the arrow starts moving
	
	# 6. Reset charge and start cooldown
	charge_time = 0.0
	await get_tree().create_timer(attack_cooldown * 2).timeout
	can_shoot = true
# Inside Player.gd

func heal(amount):
	# Look for the child node
	var health_node = get_node_or_null("Health")
	
	if health_node:
		# Call the heal function on THAT node instead
		health_node.heal(amount)
	else:
		print("Error: Player can't find HealthNode!")
		
var coins: int = 0

func add_money(amount):
	coins += amount
	print("Coins collected: ", coins)
