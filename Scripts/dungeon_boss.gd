extends CharacterBody2D

@export_group("Settings")
@export var charge_duration: float = 4.0
@export var fire_cooldown: float = 2.0
@export var poison_cooldown: float = 2.0
@export var electric_cooldown: float = 3.0
@export var bomb_cooldown: float = 4.0

@export_group("Projectiles")
@export var fire_projectile: PackedScene 
@export var slime_puddle: PackedScene
@export var electricity_scene: PackedScene
@export var bomb_scene: PackedScene

@onready var marker = $Marker2D
@onready var timer = $DecisionTimer 
@onready var badges = $BadgesContainer
@onready var shield_node = $Shield

# Specific Badge References
@onready var fire_badge = $BadgesContainer/FireBadge
@onready var poison_badge = $BadgesContainer/PoisonBadge
@onready var electric_badge = $BadgesContainer/ElectricBadge

var can_attack := true
var is_invincible := true

# --- ADD TO TOP OF SCRIPT ---
@export var boss_health: int = 100
@export var badge_hp_max: int = 25

# Dictionary to keep track of the health for your 4 boxes
var badge_hps = {
	"Firebox": 25,
	"PoisonBox": 25,
	"ElectricBox": 25,
	"BombBox": 25
	}
	
func _ready():
	print("--- TITAN INITIALIZING ---")
	
	# 1. Start the AI
	if timer:
		timer.wait_time = 1.5 
		timer.start()
	
	# 2. Force Shield Activation
	if shield_node:
		shield_node.show()
		shield_node.monitoring = true
		shield_node.monitorable = true
		# Ensure the shield doesn't ignore the player's bullets
		shield_node.collision_layer = 4 # Or whatever your Boss Layer is
		shield_node.collision_mask = 2  # Looking for Player Bullets
	
	# 3. Force Badge Hitboxes Activation
	for badge in badges.get_children():
		if badge is Area2D:
			badge.monitoring = true
			badge.monitorable = true
			# Force physics layers via code just in case
			badge.collision_layer = 4 
			badge.collision_mask = 2
			print("Forced hitbox ON for: ", badge.name)
	
	# 4. Check for Shape Errors
	_check_physics_sanity()

func _check_physics_sanity():
	# This helper prints a warning if you forgot to add a Shape to a node
	for badge in badges.get_children():
		var shape = badge.get_node_or_null("CollisionShape2D")
		if shape and shape.shape == null:
			print("!!! CRITICAL ERROR: ", badge.name, " has no SHAPE assigned in Inspector!")
	
func _physics_process(_delta):
	# Shield Breaking Logic
	if badges and badges.get_child_count() == 0 and is_invincible:
		is_invincible = false
		if shield_node: shield_node.hide()
		print("DEBUG: SHIELD DESTROYED")

func _on_decision_timer_timeout():
	if not can_attack: return
	
	# Check available badges
	var has_fire = badges.has_node("FireBadge")
	var has_poison = badges.has_node("PoisonBadge")
	var has_elec = badges.has_node("ElectricBadge")
	var has_bomb = badges.has_node("BombBadge")
	
	var available_attacks = []
	if has_fire: available_attacks.append("_execute_fire_sequence")
	if has_poison: available_attacks.append("_execute_poison_spiral")
	if has_elec: available_attacks.append("_execute_electric_sequence")
	if has_bomb: available_attacks.append("_execute_bomb_sequence")
	
	if available_attacks.size() > 0:
		can_attack = false # LOCK
		var chosen = available_attacks.pick_random()
		print("DEBUG: Choosing Attack: ", chosen)
		call(chosen)

# --- FIRE ATTACK (Spiral) ---
func _execute_fire_sequence():
	var charge_tween = get_tree().create_tween().set_loops(4)
	if is_instance_valid(fire_badge):
		charge_tween.tween_property(fire_badge, "modulate", Color(5, 1, 0.5), 0.5)
		charge_tween.tween_property(fire_badge, "modulate", Color.WHITE, 0.5)
	if shield_node:
		charge_tween.parallel().tween_property(shield_node, "modulate", Color(2, 2, 0), 0.5)
		charge_tween.parallel().tween_property(shield_node, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout
	
	if is_instance_valid(fire_badge): fire_badge.modulate = Color(5, 1, 0.5)
	var waves = 12
	var p_per_wave = 10
	for w in range(waves):
		for i in range(p_per_wave):
			if fire_projectile:
				var fire = fire_projectile.instantiate()
				get_tree().current_scene.add_child(fire)
				fire.global_position = marker.global_position
				fire.scale = Vector2(0.85, 0.85)
				var angle = (i * (TAU/p_per_wave)) + (w * 0.2) + deg_to_rad(randf_range(-15, 15))
				var dir = Vector2(cos(angle), sin(angle))
				var tween = get_tree().create_tween()
				tween.tween_property(fire, "global_position", fire.global_position + (dir * 450), 2.5)
				tween.parallel().tween_property(fire, "modulate:a", 0, 2.5) 
				tween.tween_callback(fire.queue_free) 
		await get_tree().create_timer(5.0 / waves).timeout
	
	if is_instance_valid(fire_badge): fire_badge.modulate = Color.WHITE
	await get_tree().create_timer(fire_cooldown).timeout
	can_attack = true

# --- POISON ATTACK (3-Line Slow Sweep) ---
func _execute_poison_spiral():
	var charge_tween = get_tree().create_tween().set_loops(4)
	if is_instance_valid(poison_badge):
		charge_tween.tween_property(poison_badge, "modulate", Color(0, 5, 0), 0.5)
		charge_tween.tween_property(poison_badge, "modulate", Color.WHITE, 0.5)
	if shield_node:
		charge_tween.parallel().tween_property(shield_node, "modulate", Color(0, 2, 0), 0.5)
		charge_tween.parallel().tween_property(shield_node, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout
	
	if is_instance_valid(poison_badge): poison_badge.modulate = Color(0, 5, 0)
	var duration = 5.0
	var shots_per_second = 30
	var rotation_speed = 1.5 
	var total_shots = int(duration * shots_per_second)
	
	for i in range(total_shots):
		for line in range(3):
			if slime_puddle:
				var slime = slime_puddle.instantiate()
				get_tree().current_scene.add_child(slime)
				slime.global_position = marker.global_position
				var base_angle = i * (rotation_speed / shots_per_second)
				var line_offset = line * (TAU / 3.0)
				var final_angle = base_angle + line_offset
				var dir = Vector2(cos(final_angle), sin(final_angle))
				var tween = get_tree().create_tween()
				tween.tween_property(slime, "global_position", slime.global_position + (dir * 350), 1.8)
				tween.tween_interval(1.0)
				tween.parallel().tween_property(slime, "modulate:a", 0, 0.5)
				tween.tween_callback(slime.queue_free)
		await get_tree().create_timer(1.0 / shots_per_second).timeout
	
	if is_instance_valid(poison_badge): poison_badge.modulate = Color.WHITE
	await get_tree().create_timer(poison_cooldown).timeout
	can_attack = true

# --- ELECTRIC ATTACK (Spinning Outward Cage) ---
func _execute_electric_sequence():
	var charge_tween = get_tree().create_tween().set_loops(4)
	if is_instance_valid(electric_badge):
		charge_tween.tween_property(electric_badge, "modulate", Color(0, 4, 10), 0.5)
		charge_tween.tween_property(electric_badge, "modulate", Color.WHITE, 0.5)
	if shield_node:
		charge_tween.parallel().tween_property(shield_node, "modulate", Color(0, 2, 5), 0.5)
		charge_tween.parallel().tween_property(shield_node, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout

	var pylon_count = 6
	var current_radius = 0.0      
	var max_radius = 450.0        
	var expansion_speed = 75.0   
	
	var cage_node = Node2D.new() 
	get_tree().current_scene.add_child(cage_node)
	cage_node.global_position = global_position 

	var pylon_list = []
	for i in range(pylon_count):
		if electricity_scene:
			var pylon = electricity_scene.instantiate()
			cage_node.add_child(pylon)
			pylon.scale = Vector2(2, 2)
			var angle = i * (TAU / pylon_count)
			pylon_list.append({"node": pylon, "angle": angle})

	if is_instance_valid(electric_badge): electric_badge.modulate = Color(0, 4, 10)
	
	var start_time = Time.get_ticks_msec()
	while (Time.get_ticks_msec() - start_time) < (5.0 * 1000):
		if not is_instance_valid(cage_node): break
		cage_node.rotation += 0.08
		if current_radius < max_radius:
			current_radius += expansion_speed * get_process_delta_time()
			for p_data in pylon_list:
				if is_instance_valid(p_data.node):
					p_data.node.position = Vector2(cos(p_data.angle), sin(p_data.angle)) * current_radius
		await get_tree().process_frame 

	if is_instance_valid(cage_node):
		var fade_tween = get_tree().create_tween()
		fade_tween.tween_property(cage_node, "modulate:a", 0, 0.5)
		fade_tween.tween_callback(cage_node.queue_free)
	
	if is_instance_valid(electric_badge): electric_badge.modulate = Color.WHITE
	await get_tree().create_timer(electric_cooldown).timeout
	can_attack = true

# --- BOMB ATTACK (Tightened Mortar Rain) ---
func _execute_bomb_sequence():
	var bomb_badge = badges.get_node_or_null("BombBadge")
	var charge_tween = get_tree().create_tween().set_loops(4)
	if is_instance_valid(bomb_badge):
		charge_tween.tween_property(bomb_badge, "modulate", Color(5, 0, 0), 0.5)
		charge_tween.tween_property(bomb_badge, "modulate", Color.WHITE, 0.5)
	if shield_node:
		charge_tween.parallel().tween_property(shield_node, "modulate", Color(2, 0, 0), 0.5)
		charge_tween.parallel().tween_property(shield_node, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout
	
	var bomb_count = 10
	var player = get_tree().get_first_node_in_group("Player")
	
	for i in range(bomb_count):
		if bomb_scene:
			var bomb = bomb_scene.instantiate()
			get_tree().current_scene.add_child(bomb)
			bomb.global_position = marker.global_position
			
			# FIX: Default to landing near the Boss if player is missing
			var target_pos = global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
			
			# FIX: If player exists, land in a tight 150px circle around them
			if player:
				var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
				target_pos = player.global_position + random_offset
			
			# Arcing Animation
			var travel_time = 1.0 # Slightly faster travel
			var tween = get_tree().create_tween().set_parallel(true)
			tween.tween_property(bomb, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Height effect
			var h_tween = get_tree().create_tween()
			h_tween.tween_property(bomb, "scale", Vector2(2.0, 2.0), travel_time/2)
			h_tween.tween_property(bomb, "scale", Vector2(1, 1), travel_time/2)
			
		await get_tree().create_timer(0.3).timeout
	
	await get_tree().create_timer(bomb_cooldown).timeout
	can_attack = true
