extends CharacterBody2D

## --- Exports ---
@export_group("Movement")
@export var base_speed := 90        # Slightly faster base
@export var max_speed := 220       # Higher top speed for repositioning
@export var min_distance := 90.0   # Range at which it starts shooting
@export var max_distance := 180.0

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var shoot_cooldown := 0.4  # MUCH faster attack rate (was 1.0)
@export var burst_count := 1       # Potential for future burst logic

@export_group("AI Behavior")
@export var flee_offset_range := 24
@export var wall_bounce_duration := 0.5 
@export var swarm_radius := 20
@export var swarm_force := 2.0

## --- Internal Variables ---
var time_since_shot := 0.0
var wall_escape_timer := 0.0
var escape_direction := Vector2.ZERO
var player: Node2D
var rng = RandomNumberGenerator.new()

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	rng.randomize()
	if not is_in_group("enemies"):
		add_to_group("enemies")

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
func shoot(dir: Vector2) -> void:
	if not projectile_scene: return
	
	var proj = projectile_scene.instantiate()
	proj.global_position = global_position
	
	# Safety check for projectile property
	if "direction" in proj:
		proj.direction = dir
		
	get_parent().add_child(proj)
