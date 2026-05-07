extends CharacterBody2D

# --- CONFIGURATION ---
@export_group("Combat")
@export var bullet_scene: PackedScene
@export var speed: float = 130.0         # Sliding works best at 200+
@export var stop_distance: float = 65.0  # Distance to stop and shoot
@export var fire_rate: float = 1.4

# --- NODES ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var marker: Marker2D = $Shoot
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var can_fire: bool = true

func _ready() -> void:
	await get_tree().process_frame
	# Automatically finds player in the "player" group
	player = get_tree().get_first_node_in_group("player")
	makepath()
	
	# Tight settings for corner navigation
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

func _physics_process(_delta: float) -> void:
	if not player: return

	makepath()
	
	var dist_to_player = global_position.distance_to(player.global_position)
	
	# --- THE RAYCAST CHECK (DIRECT PATH) ---
	var has_direct_path = _check_raycast_to_player()

	# --- ROTATION & FLIP ---
	var dir_to_player = global_position.direction_to(player.global_position)
	sprite.rotation = lerp_angle(sprite.rotation, dir_to_player.angle() + PI, 0.2)
	var current_rot = fposmod(sprite.rotation, TAU)
	sprite.flip_v = (current_rot > PI/2 and current_rot < 3*PI/2)

	# --- BRAIN LOGIC ---
	# IF no direct path OR too far away: Move (Slide)
	if not has_direct_path or dist_to_player > stop_distance:
		_handle_navigation_movement()
		_play_anim("Searching")
	else:
		# IF direct path AND close: Stop and Shoot
		velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)
		_play_anim("Shooting")
		if can_fire:
			_shoot()

	# move_and_slide() allows the bot to glide against walls
	move_and_slide()

func _handle_navigation_movement() -> void:
	if nav_agent.is_navigation_finished(): return
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos)
	velocity = dir * speed

func makepath() -> void:
	if player:
		nav_agent.target_position = player.global_position

func _check_raycast_to_player() -> bool:
	var space_state = get_world_2d().direct_space_state
	if not player: return false
	
	var ray_start = global_position
	var query = PhysicsRayQueryParameters2D.create(ray_start, player.global_position)
	
	# Check everything
	query.collision_mask = 0xFFFFFFFF
	query.exclude = [self.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_node = result.collider
		
		# 1. Check if it's the player
		if hit_node == player:
			print("DEBUG: Clear shot to Player")
			return true
		
		# 2. Check if the node is named "Walls" OR is a TileMapLayer
		if hit_node.name == "Walls" or hit_node is TileMapLayer:
			print("DEBUG: Blocked by: ", hit_node.name, " (TileMapLayer detected)")
			return false
		else:
			print("DEBUG: Blocked by something else: ", hit_node.name)
			return false
			
	print("DEBUG: Ray hit nothing")
	return false
	

func _shoot() -> void:
	can_fire = false
	if bullet_scene:
		var b = bullet_scene.instantiate()
		get_tree().current_scene.add_child(b)
		b.global_position = marker.global_position
		b.direction = global_position.direction_to(player.global_position)
		b.scale = Vector2(0.75, 0.75)
		if b.has_method("look_at"): b.look_at(player.global_position)
	
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _play_anim(anim_name: String):
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _on_timer_timeout():
	makepath()
