extends CharacterBody2D

@export var speed_wander := 40.0
@export var speed_chase := 85.0
@export var damage := 1

var player: Node2D = null
var is_chasing := false
var wander_direction := Vector2.ZERO
var target_in_range: Node2D = null

func _ready():
	print("--- PEON DEBUG START ---")
	await get_tree().process_frame
	
	# Check Player Group
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("SUCCESS: Found Player in 'player' group.")
	else:
		print("ERROR: No node found in 'player' group! Check your Player node groups.")

	add_to_group("enemies")
	
	# Safety Check for Nodes and Signals
	_connect_debug_signal("Health", "died", queue_free)
	_connect_debug_signal("DetectionRange", "body_entered", _on_detection_entered)
	_connect_debug_signal("DetectionRange", "body_exited", _on_detection_exited)
	_connect_debug_signal("Hurtbox", "body_entered", _on_hurtbox_body_entered)
	_connect_debug_signal("Hurtbox", "body_exited", _on_hurtbox_body_exited)
	
	if has_node("Hurtbox/AttackTimer"):
		$Hurtbox/AttackTimer.timeout.connect(_on_attack_timer_timeout)
		print("SUCCESS: AttackTimer connected.")
	
	if has_node("WanderTimer"):
		$WanderTimer.timeout.connect(_on_wander_timer_timeout)
		_on_wander_timer_timeout()
		print("SUCCESS: WanderTimer started.")

func _connect_debug_signal(node_name: String, sig_name: String, callable: Callable):
	if has_node(node_name):
		get_node(node_name).connect(sig_name, callable)
		print("SIGNAL OK: ", node_name, " connected to ", sig_name)
	else:
		print("CRITICAL ERROR: Node '", node_name, "' not found in Peon scene!")

func _physics_process(_delta):
			
	if is_chasing and player:
		# Move toward player
		velocity = global_position.direction_to(player.global_position) * speed_chase
		
		# --- COMBAT CHECK ---
		var dist = global_position.distance_to(player.global_position)
		
		if dist < 12: # Your requested 35px bite range
			# If we aren't already biting, start biting
			if $Hurtbox/AttackTimer.is_stopped():
				print("BITE: Distance is ", dist, ". Damage Dealt!")
				target_in_range = player
				attack_player()
				$Hurtbox/AttackTimer.start()
		elif dist > 15 : # Stop biting if the player runs away
			if not $Hurtbox/AttackTimer.is_stopped():
				print("BITE STOPPED: Player escaped.")
				target_in_range = null
				$Hurtbox/AttackTimer.stop()
	else:
		# Wander Logic
		velocity = wander_direction * speed_wander
		if is_on_wall():
			wander_direction = get_wall_normal().rotated(randf_range(-PI/4, PI/4))
	
	# Handle Animations
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.stop()
		
	move_and_slide()

# --- DETECTION DEBUG ---
func _on_detection_entered(body):
	print("DETECTION: Something entered range: ", body.name)
	if body.is_in_group("player"):
		print("DETECTION: Target is PLAYER. Starting chase.")
		is_chasing = true

func _on_detection_exited(body):
	if body.is_in_group("player"):
		print("DETECTION: Player left range. Stopping chase.")
		is_chasing = false

# --- WANDER DEBUG ---
func _on_wander_timer_timeout():
	if not is_chasing:
		var angle = randf_range(0, 2 * PI)
		wander_direction = Vector2(cos(angle), sin(angle))
		print("WANDER: Changed direction to ", wander_direction)

# --- COMBAT DEBUG ---
func _on_hurtbox_body_entered(body):
	print("HURTBOX: Touched: ", body.name)
	if body.is_in_group("player"):
		print("HURTBOX: Biting player!")
		target_in_range = body
		attack_player()
		$Hurtbox/AttackTimer.start()

func _on_hurtbox_body_exited(body):
	if body == target_in_range:
		print("HURTBOX: Player escaped bite range.")
		target_in_range = null
		$Hurtbox/AttackTimer.stop()

func _on_attack_timer_timeout():
	print("ATTACK: Repeating bite...")
	attack_player()

func attack_player():
	if target_in_range:
		if target_in_range.has_method("take_damage"):
			target_in_range.take_damage(damage, global_position)
		else:
			print("ERROR: Player is missing 'take_damage' function!")
			
func take_damage(amount: int, _source_pos: Vector2 = Vector2.ZERO):
	if has_node("Health"):
		$Health.take_damage(amount)
