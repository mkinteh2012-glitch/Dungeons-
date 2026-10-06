extends CharacterBody2D

# --- CONFIGURATION ---
@export_group("Combat")
@export var bullet_scene: PackedScene
@export var speed: float = 130.0         # Sliding works best at 200+
@export var stop_distance: float = 65.0  # Distance to stop and shoot
@export var fire_rate: float = 1.4
@export var retreat_dist: float = 30.0
@export var windup_time: float = 0.3

# --- NODES ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var marker: Marker2D = $Shoot
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var can_fire: bool = true
var is_aim: bool = false
var react_timer: float = 0.0

# --- STUN VARIABLES ---
var isstun: bool = false
var stun_timer: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	# Automatically finds player in the "player" group
	player = get_tree().get_first_node_in_group("player")
	makepath()
	
	# Tight settings for corner navigation
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

func _physics_process(_delta: float) -> void:
	if isstun:
		handlestun(_delta)
		return
		
	if not player or is_aim: 
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	
	# --- THE RAYCAST CHECK (DIRECT PATH) ---
	var has_direct_path = _check_raycast_to_player()

	# --- ROTATION & FLIP ---
	var dir_to_player = global_position.direction_to(player.global_position)
	sprite.rotation = lerp_angle(sprite.rotation, dir_to_player.angle() + PI, 0.2)
	var current_rot = fposmod(sprite.rotation, TAU)
	sprite.flip_v = (current_rot > PI / 2.0 and current_rot < 3.0 * PI / 2.0)

	# --- BRAIN LOGIC ---
	if dist_to_player < retreat_dist and has_direct_path:
		var awaydir = player.global_position.direction_to(global_position)
		velocity = awaydir * (speed * 0.75)
		_play_anim("Searching")
		
	elif not has_direct_path or dist_to_player > stop_distance:
		_handle_navigation_movement()
		_play_anim("Searching")
		react_timer = 0.2
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)	
		
		if react_timer > 0.0:
			react_timer -= _delta
			_play_anim("Searching")
		elif can_fire:
			windup()	
			
	move_and_slide()

# --- STUN HANDLERS ---
func apply_stun(duration: float) -> void:
	stun(duration)

func stun(duration: float) -> void:
	isstun = true
	stun_timer = duration
	is_aim = false
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = Color(0.4, 0.8, 2.5) # Blue/cyan stun indicator

func handlestun(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	
	stun_timer -= delta
	if stun_timer <= 0.0:
		isstun = false
		if sprite:
			sprite.modulate = Color.WHITE

# --- COMBAT & NAVIGATION ---
func windup() -> void:
	can_fire = false
	is_aim = true
	velocity = Vector2.ZERO
	_play_anim("Charge")
	
	await get_tree().create_timer(windup_time).timeout
	
	if is_instance_valid(player):
		_shoot()
	is_aim = false

func _handle_navigation_movement() -> void:
	if nav_agent.is_navigation_finished(): 
		return
	var next_path_pos = nav_agent.get_next_path_position()
	makepath()
	var dir = global_position.direction_to(next_path_pos)
	velocity = dir * speed

func makepath() -> void:
	if player:
		nav_agent.target_position = player.global_position

func _check_raycast_to_player() -> bool:
	var space_state = get_world_2d().direct_space_state
	if not player: 
		return false
	
	var ray_start = global_position
	var query = PhysicsRayQueryParameters2D.create(ray_start, player.global_position)
	query.collision_mask = 0xFFFFFFFF
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_node = result.collider
		if hit_node == player:
			return true
		if hit_node.name == "Walls" or hit_node is TileMapLayer:
			return false
		else:
			return false
			
	return false

func _shoot() -> void:
	can_fire = false
	if bullet_scene:
		var b = bullet_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = marker.global_position
		b.direction = global_position.direction_to(player.global_position)
		b.scale = Vector2(0.75, 0.75)
		if b.has_method("look_at"): 
			b.look_at(player.global_position)
	is_aim = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _play_anim(anim_name: String) -> void:
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _on_timer_timeout() -> void:
	if is_instance_valid(player):
		nav_agent.target_position = player.global_position
