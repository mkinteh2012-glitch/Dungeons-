extends CharacterBody2D

# --- NEW SLIME EXPORTS ---
@export_group("Slime Settings")
@export var puddle_scene: PackedScene 
@export var puddle_distance: float = 20.0 

@export_group("Movement")
@export var speed_wander := 20
@export var speed_chase := 40
@export var damage := 1

# --- NODES ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var is_chasing := false
var wander_direction := Vector2.ZERO
var target_in_range: Node2D = null
var last_puddle_pos := Vector2.ZERO

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemy")
	
	last_puddle_pos = global_position 
	
	# Navigation setup
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	
	# Connect signals
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
		# PATHFINDING LOGIC
		makepath()
		var next_path_pos = nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next_path_pos) * speed_chase
		
		# Attack logic
		var dist = global_position.distance_to(player.global_position)
		if dist < 12:
			if $Hurtbox/AttackTimer.is_stopped():
				target_in_range = player
				attack_player()
				$Hurtbox/AttackTimer.start()
		elif dist > 15:
			if not $Hurtbox/AttackTimer.is_stopped():
				target_in_range = null
				$Hurtbox/AttackTimer.stop()
	else:
		# WANDER LOGIC
		velocity = wander_direction * speed_wander
		if is_on_wall():
			wander_direction = get_wall_normal().rotated(randf_range(-PI/4, PI/4))
	
	# --- TRAIL LOGIC ---
	if global_position.distance_to(last_puddle_pos) > puddle_distance:
		spawn_trail()
		last_puddle_pos = global_position

	# Sprite Animation
	if velocity.length() > 0:
		sprite.play("walk")
		sprite.flip_h = velocity.x < 0
	else:
		sprite.stop()
		
	# move_and_slide() makes the slime glide along brick corners
	move_and_slide()

func makepath():
	if player:
		nav_agent.target_position = player.global_position

func spawn_trail():
	if puddle_scene:
		var p = puddle_scene.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position
		p.rotation = randf_range(0, TAU)
		p.z_index = 1 

# --- SIGNAL FUNCTIONS ---
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
	if target_in_range and target_in_range.has_method("take_damage"):
		target_in_range.take_damage(damage, global_position)
		
func take_damage(amount: int, _source_pos: Vector2 = Vector2.ZERO):
	if has_node("Health"):
		$Health.take_damage(amount)
