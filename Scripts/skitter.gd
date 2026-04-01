extends CharacterBody2D

## --- Exports ---
@export var max_health := 50
var current_health: int

@export_group("Movement")
@export var base_speed := 90        # Slightly faster base
@export var max_speed := 220       # Higher top speed for repositioning
@export var min_distance := 90.0   # Range at which it starts shooting
@export var max_distance := 180.0

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var shoot_cooldown := 0.4  # MUCH faster attack rate (was 1.0)
@export var burst_count := 3 
@export var burst_chance := 0.1    

@export_group("AI Behavior")
@export var flee_offset_range := 24
@export var wall_bounce_duration := 0.5 
@export var swarm_radius := 20
@export var swarm_force := 2.0
@export var accuracy_error : float = 15.0 # Degrees of possible error

## --- Internal Variables ---
var time_since_shot := 0.0
var wall_escape_timer := 0.0
var escape_direction := Vector2.ZERO
var player: Node2D
var rng = RandomNumberGenerator.new()

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	current_health = max_health # Initialize health
	rng.randomize()
	if not is_in_group("enemies"):
		add_to_group("enemies")

# This MUST be exactly 'take_damage' to match the dagger's check
func take_damage(amount: int) -> void:
	print("Enemy took ", amount, " damage!")
	current_health -= amount
	
	# Visual feedback (flash red)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	# 1. Player Validation
	if not player or not player.is_inside_tree():
		player = get_tree().get_root().get_node_or_null("Game/Player")
		if not player:
			return

	time_since_shot += delta
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = Vector2.ZERO
	var speed = 0.0

	# 2. Attack Logic (Prioritized)
	# Now checks for shooting regardless of movement state if in range
	if distance <= min_distance and time_since_shot >= shoot_cooldown:
		shoot(to_player.normalized())
		time_since_shot = 0.0

	# 3. Movement State Logic
	if wall_escape_timer > 0:
		wall_escape_timer -= delta
		direction = escape_direction
		speed = max_speed
		anim.play("Run")
	else:
		if distance > max_distance:
			# If too far, aggressive enemies might "Lurk" or move slightly closer
			anim.play("Idle")
			direction = Vector2.ZERO
		else:
			# Skirmishing/Fleeing behavior
			var offset = Vector2(rng.randf_range(-flee_offset_range, flee_offset_range),
								 rng.randf_range(-flee_offset_range, flee_offset_range))
			direction = (-to_player + offset).normalized()
			
			# Speed ramps up the closer the player gets
			var speed_t = clamp((max_distance - distance) / (max_distance - min_distance), 0.0, 1.0)
			speed = lerp(float(base_speed), float(max_speed), speed_t)
			anim.play("Run")

	# 4. Swarm Avoidance
	var repulsion = Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self: continue
		var dist_vec = global_position - enemy.global_position
		var dist = dist_vec.length()
		if dist < swarm_radius and dist > 0:
			repulsion += dist_vec.normalized() * (swarm_radius - dist) * swarm_force

	# 5. Final Velocity Assembly
	direction = (direction + repulsion).normalized()

	if direction.x != 0:
		anim.flip_h = direction.x < 0

	velocity = direction * speed
	
	# 6. Wall Interaction
	if move_and_slide():
		handle_wall_collision()

## --- Wall Logic ---
func handle_wall_collision():
	var collision = get_last_slide_collision()
	if collision:
		var normal = collision.get_normal()
		# Pick a random "bounce" direction away from wall
		var random_angle = rng.randf_range(-PI/4, PI/4) 
		escape_direction = normal.rotated(random_angle).normalized()
		wall_escape_timer = wall_bounce_duration

## --- Combat ---
## --- Combat ---
## --- Combat ---
## --- Combat ---
func shoot(dir: Vector2) -> void:
	if not projectile_scene: return
	
	# --- 1. APPLY INACCURACY ---
	# This shifts the ENTIRE attack (single or burst) by a random amount
	var error_deg = rng.randf_range(-accuracy_error, accuracy_error)
	var aimed_dir = dir.rotated(deg_to_rad(error_deg))
	
	# Determine if this attack is a burst or a single shot
	var is_burst = rng.randf() < burst_chance
	var shots_to_fire = burst_count if is_burst else 1
	
	for i in range(shots_to_fire):
		var proj = projectile_scene.instantiate()
		
		# --- 2. APPLY SPREAD ---
		# This is a TINY variation (±4) so burst bullets don't overlap
		var spread = deg_to_rad(rng.randf_range(-4, 4))
		var final_dir = aimed_dir.rotated(spread)
		
		proj.global_position = global_position
		get_tree().current_scene.add_child(proj)
		
		if "direction" in proj:
			proj.direction = final_dir
		
		proj.rotation = final_dir.angle()
		
		if shots_to_fire > 1 and i < shots_to_fire - 1:
			await get_tree().create_timer(0.12).timeout
