extends CharacterBody2D

var target_position = Vector2.ZERO
var can_attack = true
@export var min_dist = 60.0 # Don't get closer than this
@export var max_dist = 150.0 # Don't wander further than this
enum State { WALK, RUSH, SLAM, STUNNED }
var current_state = State.WALK
@export var cooldown_time = 4.0 # Seconds between attacks
@export var ring_scene: PackedScene
@export var speed: float = 120.0 # Make sure ': float = 120.0' is there
@export var rush_speed = 400.0

var player = null

func _ready():
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("DEBUG ERROR: Player not found! Make sure player is in 'player' group.")
	
	$DecisionTimer.start()
	print("DEBUG: Boss Ready. Initial State: WALK")

func _physics_process(_delta):
	match current_state:
		State.WALK:
			_state_walk()
		State.RUSH:
			_state_rush()
		State.SLAM, State.STUNNED:
			velocity = Vector2.ZERO # Stop moving
	# Gently push the boss away if he overlaps the player too much
	if current_state == State.WALK and player:
		if global_position.distance_to(player.global_position) < 50:
			var push_dir = player.global_position.direction_to(global_position)
			velocity += push_dir * speed # Nudge him away
	move_and_slide()
	
	if current_state == State.RUSH:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var target = collision.get_collider()
			if target.is_in_group("player"):
				if target.has_method("take_damage"):
					target.take_damage(1)
					# Optionally: knock the player back or end the rush
					_enter_state(State.WALK)

func _state_walk():
	# If he's close to his target spot, pick a new one
	if global_position.distance_to(target_position) < 30:
		_pick_random_spot()
	
	var dir = global_position.direction_to(target_position)
	velocity = dir * speed

func _state_rush():
	# Move in fixed velocity set in _enter_state
	if is_on_wall():
		print("DEBUG: Hit wall! Entering STUNNED")
		_enter_state(State.STUNNED)

func _enter_state(new_state):
	current_state = new_state
	print("DEBUG: Switched to State: ", State.keys()[new_state])
	
	match current_state:
		State.WALK:
			modulate = Color.WHITE
			
		State.RUSH:
			velocity = Vector2.ZERO # Freeze to aim
			modulate = Color.RED
			
			if player:
				# Face the player before locking direction
				$AnimatedSprite2D.flip_h = (player.global_position.x < global_position.x)
				var final_dir = global_position.direction_to(player.global_position)
				
				# Telegraph: Small pause so player can react
				await get_tree().create_timer(0.6).timeout 
				
				# Launch!
				velocity = final_dir * rush_speed
			
			await get_tree().create_timer(1.2).timeout
			if current_state == State.RUSH:
				_enter_state(State.WALK)
				
		State.SLAM:
			velocity = Vector2.ZERO
			modulate = Color.CYAN
			
			if player:
				$AnimatedSprite2D.flip_h = (player.global_position.x < global_position.x)
			
			# Brief pause before the first ring pops
			await get_tree().create_timer(0.5).timeout 
			_perform_earthquake()
			
		State.STUNNED:
			velocity = Vector2.ZERO
			await get_tree().create_timer(2.0).timeout
			_enter_state(State.WALK)

func _perform_earthquake():
	print("DEBUG: Slamming ground!")
	# Spawn 3 rings
	for i in range(3):
		_spawn_ring()
		await get_tree().create_timer(0.4).timeout
	
	_enter_state(State.WALK)

func _spawn_ring():
	if not ring_scene:
		print("DEBUG ERROR: No Ring Scene assigned in Inspector!")
		return
	var ring = ring_scene.instantiate()
	# Using Marker2D named 'Center' or just global_position
	var spawn_pos = get_node_or_null("Center")
	ring.global_position = spawn_pos.global_position if spawn_pos else global_position
	get_tree().current_scene.add_child(ring)

func _on_decision_timer_timeout():
	# Only attack if walking AND the 3-second cooldown is finished
	if current_state == State.WALK and can_attack:
		can_attack = false # Close the gate
		
		# Pick Move
		if randf() > 0.5: _enter_state(State.RUSH)
		else: _enter_state(State.SLAM)
		
		# Start Cooldown Timer (3 seconds until he can attack again)
		await get_tree().create_timer(4.0).timeout
		can_attack = true

func _start_cooldown():
	can_attack = false
	print("DEBUG: Attack used. Cooldown started.")
	
	# This timer runs in the background while the boss finishes his attack
	await get_tree().create_timer(cooldown_time + 1.0).timeout 
	
	can_attack = true
	print("DEBUG: Cooldown over. Boss can attack again.")
func _pick_random_spot():
	if not player: return
	# Get a random direction vector
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Pick a spot in a ring around the player
	var distance = randf_range(min_dist, max_dist)
	target_position = player.global_position + (random_dir * distance)
