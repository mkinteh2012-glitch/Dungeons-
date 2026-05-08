extends CharacterBody2D



@export_group("Spawning")
@export var badge_scene: PackedScene 
@export var badge_offsets: Array[Vector2] = [
	Vector2(-27, -27), Vector2(27, -27), 
	Vector2(-27, 27), Vector2(27, 27)
]

@export_group("AI Settings")
@export var charge_duration: float = 4.0

@export_group("Projectiles")
@export var fire_projectile: PackedScene 
@export var slime_puddle: PackedScene
@export var electricity_scene: PackedScene
@export var bomb_scene: PackedScene

@export_group("Boss Stats")
@export var boss_health: int = 100
@export var fire_cooldown: float = 4.0
@export var poison_cooldown: float = 3.0
@export var electric_cooldown: float = 3.0
@export var bomb_cooldown: float = 3.0

@onready var marker = $Marker2D
@onready var timer = $DecisionTimer 
@onready var shield_visual = $Shield
@onready var shield_hitbox = $SheieldBox # This should be the Area2D/StaticBody


var can_attack := true
var is_invincible := true
var badge_types = ["fire", "poison", "electric", "bomb"]
var player: CharacterBody2D = null


@export_group("Panic Settings")
@export var panic_speed: float = 250.0  # Slower than before for that "Rory" feel
@export var panic_radius: float = 180.0

var panic_direction: Vector2 = Vector2.ONE.normalized()

# Assuming you have an AnimatedSprite2D or Sprite2D with an AnimationPlayer
@onready var sprite = $AnimatedSprite2D 

func _physics_process(delta):
	player = get_tree().root.find_child("Player", true, false)
	if not is_invincible:
		# Disable shield once
		if not shield_hitbox.disabled:
			shield_hitbox.disabled = true
			if shield_visual: shield_visual.hide()
			
		_run_in_bounce(delta)
	else:
		_handle_idle_state()

func _run_in_bounce(_delta):
	# 1. Set the velocity based on current direction and speed
	velocity = panic_direction * panic_speed
	
	# 2. Reset rotation (since you don't want it to rotate anymore)
	rotation = 0
	
	# 3. Execute movement
	# move_and_slide() uses the 'velocity' property automatically in Godot 4.x
	var collided = move_and_slide()
	
	# 4. Pinball Bounce Logic
	if collided:
		# Get the normal of the surface we hit
		var collision = get_last_slide_collision()
		var normal = collision.get_normal()
		
		# Reflect the direction based on the wall's angle
		panic_direction = panic_direction.bounce(normal)
	
	# 5. Visuals: Flip and Animation
	if panic_direction.x != 0:
		sprite.flip_h = panic_direction.x < 0
	
	_play_animation("Walk")

func _handle_idle_state():
	velocity = Vector2.ZERO
	rotation = 0
	_play_animation("Idle")
	sprite.flip_h = player.global_position.x < global_position.x

func _play_animation(anim_name: String):
	# If using AnimatedSprite2D
	if sprite.has_method("play"):
		sprite.play(anim_name)
	# If using AnimationPlayer
	# $AnimationPlayer.play(anim_name)
	

func _ready():
	add_to_group("BossGroup")
	set_meta("finalboss", true) # Ensure metadata is set for badges to find you
		
	_spawn_badges()
	
	if timer:
		timer.timeout.connect(_on_decision_timer_timeout)
		timer.start()
	
	_update_shield_logic()


	
func _spawn_badges():
	if not badge_scene:
		print("ERROR: Badge Scene missing!")
		return

	var rotation_angle = deg_to_rad(45)

	for i in range(4):
		var new_badge = badge_scene.instantiate()
		add_child(new_badge)
		
		var final_offset = badge_offsets[i].rotated(rotation_angle)
		new_badge.position = final_offset 
		
		await get_tree().process_frame
		
		if new_badge.has_method("setup_badge"):
			new_badge.setup_badge(badge_types[i])

func take_damage(amount: int):
	_update_shield_logic()
	
	if is_invincible:
		_play_shield_ping()
		return
		
	boss_health -= amount
	_flash_node(self, Color(5, 0, 0))
	
	if boss_health <= 0:
		queue_free()

func _on_badge_destroyed(_type: String):
	# Wait for the node to be fully removed from group
	await get_tree().process_frame
	_update_shield_logic()

func _update_shield_logic():
	var active_badges = false
	for node in get_tree().get_nodes_in_group("BossBadges"):
		if is_instance_valid(node) and node.has_meta("bossbadge"):
			active_badges = true
			break
	
	is_invincible = active_badges
	
	if shield_visual:
		shield_visual.visible = is_invincible
	
	if shield_hitbox:
		# Use set_deferred to avoid physics errors
		for child in shield_hitbox.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", not is_invincible)

func _play_shield_ping():
	var t = get_tree().create_tween()
	t.tween_property(shield_visual, "modulate", Color(0, 5, 20), 0.05)
	t.tween_property(shield_visual, "modulate", Color.WHITE, 0.05)

func _flash_node(node, color: Color):
	var t = get_tree().create_tween()
	t.tween_property(node, "modulate", color, 0.05)
	t.tween_property(node, "modulate", Color.WHITE, 0.05)

## --- AI ATTACKS ---

func _on_decision_timer_timeout():
	if not can_attack: return
	
	var available_attacks = []
	for node in get_tree().get_nodes_in_group("BossBadges"):
		if is_instance_valid(node) and node.has_method("get_badge_type"):
			match node.get_badge_type():
				"fire": available_attacks.append("_execute_fire_sequence")
				"poison": available_attacks.append("_execute_poison_spiral")
				"electric": available_attacks.append("_execute_electric_sequence")
				"bomb": available_attacks.append("_execute_bomb_sequence")
	
	if available_attacks.size() > 0:
		can_attack = false
		var chosen = available_attacks.pick_random()
		call(chosen)

# --- HELPER TO FIND BADGE BY METADATA ---
func _get_badge_node(type: String) -> CharacterBody2D:
	for node in get_tree().get_nodes_in_group("BossBadges"):
		if is_instance_valid(node) and node.has_meta("bossbadge"):
			if node.has_method("get_badge_type") and node.get_badge_type() == type:
				return node
	return null

# --- FIRE ATTACK (Smaller balls, more space to dodge) ---
func _execute_fire_sequence():
	var badge = _get_badge_node("fire")
	if not is_instance_valid(badge): 
		can_attack = true
		return

	var charge_tween = get_tree().create_tween().set_loops(4)
	charge_tween.tween_property(badge, "modulate", Color(5, 1, 0.5), 0.5)
	charge_tween.tween_property(badge, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout
	
	badge = _get_badge_node("fire")
	if is_instance_valid(badge):
		badge.modulate = Color(5, 1, 0.5)
		var waves = 8 # Reduced waves from 12 to 8 for better dodging
		var p_per_wave = 8 # Reduced bullets per wave to create bigger gaps
		for w in range(waves):
			if not is_instance_valid(badge): break 
			for i in range(p_per_wave):
				if fire_projectile:
					var fire = fire_projectile.instantiate()
					get_tree().current_scene.add_child(fire)
					fire.global_position = marker.global_position
					
					# SCALE SET TO 0.8
					fire.scale = Vector2(0.8, 0.8)
					
					var angle = (i * (TAU/p_per_wave)) + (w * 0.4) # Faster offset rotation, but fewer bullets
					var dir = Vector2(cos(angle), sin(angle))
					var tween = get_tree().create_tween()
					# Slower projectile speed (3.0s instead of 2.5s)
					tween.tween_property(fire, "global_position", fire.global_position + (dir * 450), 3.0)
					tween.parallel().tween_property(fire, "modulate:a", 0, 3.0) 
					tween.tween_callback(fire.queue_free) 
			await get_tree().create_timer(0.6).timeout # More time between waves
		if is_instance_valid(badge): badge.modulate = Color.WHITE
	
	await get_tree().create_timer(fire_cooldown).timeout
	can_attack = true

# --- POISON ATTACK (Slower spiral spin) ---
func _execute_poison_spiral():
	var badge = _get_badge_node("poison")
	if not is_instance_valid(badge):
		can_attack = true
		return

	var charge_tween = get_tree().create_tween().set_loops(4)
	charge_tween.tween_property(badge, "modulate", Color(0, 5, 0), 0.5)
	charge_tween.tween_property(badge, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout
	
	badge = _get_badge_node("poison")
	if is_instance_valid(badge):
		badge.modulate = Color(0, 5, 0)
		var duration = 5.0
		var shots_per_second = 20 # Reduced density
		var total_shots = int(duration * shots_per_second)
		
		for i in range(total_shots):
			if not is_instance_valid(badge): break
			for line in range(3):
				if slime_puddle:
					var slime = slime_puddle.instantiate()
					get_tree().current_scene.add_child(slime)
					slime.global_position = marker.global_position
					
					# SLOWER SPIRAL: Reduced 0.1 to 0.04 for a lazy spin
					var final_angle = (i * 0.04) + (line * (TAU / 3.0))
					var dir = Vector2(cos(final_angle), sin(final_angle))
					var tween = get_tree().create_tween()
					# Slower movement (2.2s instead of 1.8s)
					tween.tween_property(slime, "global_position", slime.global_position + (dir * 300), 2.2)
					tween.tween_callback(slime.queue_free)
			await get_tree().create_timer(1.0 / shots_per_second).timeout
		if is_instance_valid(badge): badge.modulate = Color.WHITE
		
	await get_tree().create_timer(poison_cooldown).timeout
	can_attack = true

# --- ELECTRIC ATTACK (Slower expansion) ---
func _execute_electric_sequence():
	var badge = _get_badge_node("electric")
	if not is_instance_valid(badge):
		can_attack = true
		return

	var charge_tween = get_tree().create_tween().set_loops(4)
	charge_tween.tween_property(badge, "modulate", Color(0, 4, 10), 0.5)
	charge_tween.tween_property(badge, "modulate", Color.WHITE, 0.5)
	
	await get_tree().create_timer(charge_duration).timeout

	badge = _get_badge_node("electric")
	if is_instance_valid(badge):
		var cage_node = Node2D.new() 
		get_tree().current_scene.add_child(cage_node)
		cage_node.global_position = global_position 

		var pylons = []
		for i in range(10):
			if electricity_scene:
				var pylon = electricity_scene.instantiate()
				cage_node.add_child(pylon)
				var angle = i * (TAU / 10)
				pylons.append({"node": pylon, "angle": angle})

		var start_time = Time.get_ticks_msec()
		var cur_rad = 0.0
		while (Time.get_ticks_msec() - start_time) < 5000:
			if not is_instance_valid(badge) or not is_instance_valid(cage_node): break
			cage_node.rotation += 0.03 # Slower cage rotation
			cur_rad = min(cur_rad + 1.5, 400.0) # Slower expansion (1.5 instead of 3.0)
			for p in pylons:
				if is_instance_valid(p.node):
					p.node.position = Vector2(cos(p.angle), sin(p.angle)) * cur_rad
			await get_tree().process_frame 

		if is_instance_valid(cage_node):
			var ft = get_tree().create_tween()
			ft.tween_property(cage_node, "modulate:a", 0, 0.5)
			ft.tween_callback(cage_node.queue_free)
	
	await get_tree().create_timer(electric_cooldown).timeout
	can_attack = true

# --- BOMB ATTACK (Carpet Bombing / Arena Saturation) ---
func _execute_bomb_sequence():
	var badge = _get_badge_node("bomb")
	if not is_instance_valid(badge):
		can_attack = true
		return

	# Violent red warning flash
	var charge_tween = get_tree().create_tween().set_loops(6)
	charge_tween.tween_property(badge, "modulate", Color(20, 0, 0), 0.2)
	charge_tween.tween_property(badge, "modulate", Color.WHITE, 0.2)
	
	await get_tree().create_timer(charge_duration).timeout
	
	badge = _get_badge_node("bomb")
	if is_instance_valid(badge):
		var player = get_tree().get_first_node_in_group("Player")
		var total_bombs = 30 # High volume for massive spread
		
		for i in range(total_bombs):
			if not is_instance_valid(badge): break
			if bomb_scene:
				var bomb = bomb_scene.instantiate()
				get_tree().current_scene.add_child(bomb)
				bomb.global_position = marker.global_position
				bomb.scale = Vector2(2.0, 2.0) # Requested scale
				
				# --- SPREAD LOGIC ---
				# 1. Start with player position as the "Anchor"
				var target_pos = player.global_position if player else global_position
				
				# 2. Add a WIDE random offset (Spread out over the room)
				# Increased from 60 to 450 to cover the whole arena
				var spread_vector = Vector2(
					randf_range(-180, 180), 
					randf_range(-180, 180)
				)
				target_pos += spread_vector
				
				# 3. FAST travel time for difficulty
				var travel_time = randf_range(0.5, 0.9) 
				var tw = get_tree().create_tween().set_parallel(true)
				tw.tween_property(bomb, "global_position", target_pos, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				
				# Visual "Air Time" scaling
				var stw = get_tree().create_tween()
				stw.tween_property(bomb, "scale", Vector2(2.8, 2.8), travel_time / 2.0)
				stw.tween_property(bomb, "scale", Vector2(2.0, 2.0), travel_time / 2.0)
				
			# High speed "Machine Gun" firing
			await get_tree().create_timer(0.07).timeout 
	
	await get_tree().create_timer(bomb_cooldown).timeout
	can_attack = true
