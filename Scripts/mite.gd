extends CharacterBody2D

@export_group("Mite Logic")
# We use the path directly in the code now, but these exports stay for easy tweaking
@export var duplicate_time: float = 25.0
@export var max_enemies_allowed: int = 15

@export_group("Movement")
@export var speed_wander := 70
@export var speed_chase := 100
@export var damage := 1

var player: Node2D = null
var is_chasing := false
var wander_direction := Vector2.ZERO
var target_in_range: Node2D = null
var duplicate_timer: Timer

func _ready():
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	
	# --- SETUP RELIABLE TIMER ---
	duplicate_timer = Timer.new()
	add_child(duplicate_timer)
	duplicate_timer.wait_time = duplicate_time
	duplicate_timer.autostart = true
	duplicate_timer.timeout.connect(_on_duplicate_timer_timeout)
	duplicate_timer.start()
	print("Mite Logic: Timer started. Checking every 20s.")
	
	# --- SIGNALS ---
	_connect_debug_signal("Health", "died", queue_free)
	_connect_debug_signal("DetectionRange", "body_entered", _on_detection_entered)
	_connect_debug_signal("DetectionRange", "body_exited", _on_detection_exited)
	_connect_debug_signal("Hurtbox", "body_entered", _on_hurtbox_body_entered)
	_connect_debug_signal("Hurtbox", "body_exited", _on_hurtbox_body_exited)
	
	if has_node("Hurtbox/AttackTimer"):
		$Hurtbox/AttackTimer.timeout.connect(_on_attack_timer_timeout)
		
	if has_node("WanderTimer"):
		$WanderTimer.timeout.connect(_on_wander_timer_timeout)
		_on_wander_timer_timeout()

func _physics_process(_delta):
	if is_chasing and player:
		velocity = global_position.direction_to(player.global_position) * speed_chase
		var dist = global_position.distance_to(player.global_position)
		
		if dist < 12:
			if $Hurtbox/AttackTimer.is_stopped():
				target_in_range = player
				attack_player()
				$Hurtbox/AttackTimer.start()
		elif dist > 15 :
			if not $Hurtbox/AttackTimer.is_stopped():
				target_in_range = null
				$Hurtbox/AttackTimer.stop()
	else:
		velocity = wander_direction * speed_wander
		if is_on_wall():
			wander_direction = get_wall_normal().rotated(randf_range(-PI/4, PI/4))
	
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = velocity.x < 0
	else:
		$AnimatedSprite2D.stop()
		
	move_and_slide()

# --- DUPLICATION LOGIC ---
func _on_duplicate_timer_timeout():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var current_count = enemies.size()
	
	if current_count < max_enemies_allowed:
		duplicate_self(current_count)
	else:
		print("Duplication skipped: Already ", current_count, " enemies in 'enemy' group.")

func duplicate_self(count: int):
	var mite_path = "res://Sprites/Enemy/Mite.tscn"
	var scene_resource = load(mite_path)
	
	if scene_resource:
		var new_mite = scene_resource.instantiate()
		
		# 1. Add to scene BEFORE setting position
		get_tree().current_scene.add_child(new_mite)
		
		# 2. Spawn DIRECTLY on top of the current Mite
		# No offset = No out-of-bounds spawning
		new_mite.global_position = global_position
		
		print("SUCCESS: New Mite spawned at exact location. Total: ", count + 1)
		
		# 3. Isaac-style Pop-in Effect
		new_mite.scale = Vector2.ZERO
		var tw = create_tween()
		tw.tween_property(new_mite, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC)
	else:
		print("ERROR: Could not find Mite scene at: ", mite_path)

# --- BOILERPLATE & SIGNALS ---
func _connect_debug_signal(node_name: String, sig_name: String, callable: Callable):
	if has_node(node_name):
		get_node(node_name).connect(sig_name, callable)

func _on_detection_entered(body):
	if body.is_in_group("player"):
		is_chasing = true

func _on_detection_exited(body):
	if body.is_in_group("player"):
		is_chasing = false

func _on_wander_timer_timeout():
	if not is_chasing:
		var angle = randf_range(0, 2 * PI)
		wander_direction = Vector2(cos(angle), sin(angle))

func _on_hurtbox_body_entered(body):
	if body.is_in_group("player"):
		target_in_range = body
		attack_player()
		$Hurtbox/AttackTimer.start()

func _on_hurtbox_body_exited(body):
	if body == target_in_range:
		target_in_range = null
		$Hurtbox/AttackTimer.stop()

func _on_attack_timer_timeout():
	attack_player()

func attack_player():
	if target_in_range:
		if target_in_range.has_method("take_damage"):
			target_in_range.take_damage(damage, global_position)
		
func take_damage(amount: int, _source_pos: Vector2 = Vector2.ZERO):
	if has_node("Health"):
		$Health.take_damage(amount)
