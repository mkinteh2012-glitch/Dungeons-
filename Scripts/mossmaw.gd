extends CharacterBody2D

@export_group("Movement Settings")
@export var speed: float = 70.0
@export var patrol_radius: float = 100.0  # How far it can go from start
@export var idle_time: float = 2.0        # How long it waits at a spot

@export_group("Detection")
@export var attach_offset: Vector2 = Vector2(0, -4) # Moves it up 12 pixels
@export var detection_range: float = 60.0 # How close player must be to trigger chase
@export var shake_threshold: int = 8  # How many inputs needed to shake off
var shake_count: int = 0
var last_input: String = ""            # Tracks the last key pressed

var player = null
var attached_to = null
var home_position: Vector2
var target_position: Vector2
var is_waiting: bool = false

func _ready():
	home_position = global_position
	target_position = get_random_patrol_point()
	player = get_tree().get_first_node_in_group("player")
	$AnimatedSprite2D.play("default")

func _physics_process(delta):
	# 1. STATE: Attached to Player
	# We use a local variable to be 100% sure it doesn't disappear mid-calculation
	var target = attached_to 
	
	if target != null:
		$AnimatedSprite2D.play("Latch")
		check_for_shake_off()
		
		# Re-check target here just in case check_for_shake_off() just ran detach()
		if attached_to != null:
			global_position = attached_to.global_position + attach_offset
		return
	else:
		$AnimatedSprite2D.play("default")

	# 2. STATE: Chase Player (If close enough)
	if player and global_position.distance_to(player.global_position) < detection_range:
		var dir = global_position.direction_to(player.global_position)
		velocity = dir * speed
		move_and_slide()
		is_waiting = false 
		return

	# 3. STATE: Patrol Area
	patrol_logic(delta)

func detach():
	# Safety: Create a temporary reference to the player before we set attached_to to null
	var player_ref = attached_to
	
	attached_to = null
	shake_count = 0
	
	# Re-enable physics
	$CollisionShape2D.set_deferred("disabled", false)
	$DrainTimer.stop()
	
	# THE THROW: Calculate launch based on the player's movement
	var throw_direction = Vector2.UP 
	if player_ref and player_ref.velocity.length() > 0:
		throw_direction = -player_ref.velocity.normalized() 
	else:
		# If player is standing still, just pop off in a random direction
		throw_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	velocity = throw_direction * 400.0 
	
	# Standard Grace Period
	$LatchArea/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(1.5).timeout
	$LatchArea/CollisionShape2D.set_deferred("disabled", false)

func patrol_logic(_delta):
	if is_waiting:
		return

	# Move toward the patrol point
	var dir = global_position.direction_to(target_position)
	velocity = dir * (speed * 0.5) # Move slower while patrolling
	move_and_slide()

	# If we reached the point, wait a bit
	if global_position.distance_to(target_position) < 10:
		start_idle_timer()

func get_random_patrol_point() -> Vector2:
	# Picks a random spot inside the circle around its start position
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_dist = randf_range(0, patrol_radius)
	return home_position + (random_dir * random_dist)

func start_idle_timer():
	is_waiting = true
	# We use a scene tree timer so we don't need a node
	await get_tree().create_timer(idle_time).timeout
	target_position = get_random_patrol_point()
	is_waiting = false

# --- Combat Signals (Make sure these match your Node names!) ---

func _on_latch_area_body_entered(body):
	if body.is_in_group("player") and attached_to == null:
		attach(body)

func attach(target):
	attached_to = target
	$CollisionShape2D.set_deferred("disabled", true)
	$DrainTimer.start()

func _on_drain_timer_timeout():
	if attached_to and attached_to.has_method("take_damage"):
		attached_to.take_damage(1)

func take_damage(_amount):
	queue_free() # Mossmaw dies!
func check_for_shake_off():
	# 1. INSTANT DETACH: If player dodges/dashes
	if Input.is_action_just_pressed("dodge"): # <--- Change "dash" to your action name
		detach()
		return
	# Define the actions we want to track
	var directions = ["move_left", "move_right", "move_up", "move_down"]
	
	for action in directions:
		if Input.is_action_just_pressed(action):
			# Only count it if the player pressed a DIFFERENT dairection than last time
			# This prevents just holding one key down
			if action != last_input:
				shake_count += 1
				last_input = action
				
				# Visual feedback: Make the sprite jump slightly when shaken
				$AnimatedSprite2D.position = Vector2(randf_range(-1, 1), randf_range(-1, 1))
				
				if shake_count >= shake_threshold:
					detach()
