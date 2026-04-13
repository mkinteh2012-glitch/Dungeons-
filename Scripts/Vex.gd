extends CharacterBody2D

@export var walk_speed: float = 40.0
@export var dash_speed: float = 350.0
@export var flicker_dist: float = 60.0
@export var dash_trigger_dist: float = 35.0
@export var hit_range: float = 12.0 

@onready var sprite = $AnimatedSprite2D
@onready var health_node = $Health 

var player: Node2D = null
var dagger_node: Node2D = null
var hit_confirmed: bool = false 
var can_take_damage: bool = true # Prevents double-hits in one lunge

enum {HIDDEN, FLICKER, DASH, COOLDOWN, DEAD}
var state = HIDDEN

func _ready():
	player = get_tree().get_first_node_in_group("player")
	if player:
		dagger_node = player.find_child("Dagger", true, false)
	
	if health_node:
		health_node.died.connect(_on_vex_died)

func _physics_process(delta):
	if not player or state == DEAD: return

	# --- DAGGER CHECK (With Damage Cooldown) ---
	if dagger_node:
		var dist_to_dagger = global_position.distance_to(dagger_node.global_position)
		
		# Only take damage if:
		# 1. Close enough
		# 2. Player is mid-attack (can_attack is false)
		# 3. Vex isn't already on hit-cooldown
		if dist_to_dagger < 22.0 and player.get("can_attack") == false and can_take_damage:
			if health_node:
				apply_hit_logic()

	var dist = global_position.distance_to(player.global_position)
	var dir = global_position.direction_to(player.global_position)

	match state:
		HIDDEN, FLICKER:
			global_position += dir * walk_speed * delta
			sprite.flip_h = dir.x < 0
			
			if dist > flicker_dist:
				state = HIDDEN
				sprite.modulate.a = 0.0
			elif dist <= flicker_dist and dist > dash_trigger_dist:
				state = FLICKER
				sprite.modulate.a = randf_range(0.02, 0.15) 
			elif dist <= dash_trigger_dist:
				start_dash(dir)

		DASH:
			move_and_slide()
			if not hit_confirmed and dist <= hit_range:
				hit_confirmed = true
		
				if player.has_method("apply_weakness"):
					player.apply_weakness(9.0) 

func apply_hit_logic():
	can_take_damage = false # Lock the door
	health_node.take_damage(25) 
	flash_white()
	
	# Cooldown timer: he can't be hit again for 0.4s
	# This stops the "2 attacks in one lunge" bug
	await get_tree().create_timer(0.4).timeout
	can_take_damage = true

func flash_white():
	sprite.modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.15).timeout
	if state == DASH:
		sprite.modulate = Color(1, 0, 0, 1)
	else:
		sprite.modulate = Color(1, 1, 1, 1)

func start_dash(dash_dir):
	if state == DASH or state == COOLDOWN or state == DEAD: return
	state = DASH
	hit_confirmed = false 
	velocity = dash_dir * dash_speed
	sprite.modulate = Color(1, 0, 0, 1) 
	
	await get_tree().create_timer(0.4).timeout
	
	if state != DEAD:
		state = COOLDOWN
		velocity = Vector2.ZERO
		sprite.modulate = Color(0.2, 0.2, 1.0, 0.5) 
		await get_tree().create_timer(1.0).timeout
		sprite.modulate = Color(1, 1, 1, 1)
		state = HIDDEN

func _on_vex_died():
	state = DEAD
	print("Vex is playing death logic...")	
	await get_tree().create_timer(0.1).timeout
	queue_free()
