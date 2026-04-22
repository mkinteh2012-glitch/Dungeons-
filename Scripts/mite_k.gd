extends CharacterBody2D

# --- Configuration ---
@export var battle_start_delay := 4.5
@export var mites_per_wave := 4
@export var move_speed := 110.0
@export var hunt_duration := 7.6
@export var cooldown_duration := 5.0

# --- References ---
@onready var anim = $AnimatedSprite2D
@onready var shield_visual = $Shield         
@onready var shield_hitbox = $Shieldbox  
@onready var health = $Health

# --- Assets ---
var fireball_scene = preload("res://Sprites/Projectile/fireball.tscn")

# --- State Management ---
# 0: IDLE (Main)
# 1: SUMMONING (Prep)
# 2: FIREBALL (Attack)
# 3: VULNERABLE (Main)
# 4: HUNTING (Banana/Attack)
# 5: (Empty/Reserved for Prep)
enum State { IDLE, SUMMONING, FIREBALL, VULNERABLE, HUNTING, COOLDOWN }
var current_state = State.IDLE
var player = null
var is_active := false
var is_invincible := true
var current_mites = [] 
var is_transitioning := false 
var is_phase_2 := false
var phase_2_speed_mult := 1.2  # 50% faster movement
var phase_2_fire_rate := 0.5   # 50% faster shooting

func _ready():
	add_to_group("bosses")
	add_to_group("enemy")
	
	is_invincible = true
	shield_visual.show()
	shield_visual.modulate.a = 1.0
	shield_hitbox.disabled = false
	
	await get_tree().create_timer(battle_start_delay).timeout
	is_active = true
	trigger_summon_wave()

func _physics_process(_delta):
	if not is_active: return

	match current_state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)
			if is_invincible:
				check_minions()
				
		State.SUMMONING, State.COOLDOWN, State.FIREBALL:
			velocity = velocity.move_toward(Vector2.ZERO, 10.0)
			
		State.HUNTING:
			if player == null:
				player = get_tree().get_first_node_in_group("player")
			if player:
				var direction = global_position.direction_to(player.global_position)
				velocity = direction * move_speed
				anim.flip_h = direction.x < 0
				anim.play("walk")

	move_and_slide()

func trigger_summon_wave():
	current_state = State.SUMMONING
	anim.play("summon") 
	
	var spawners = get_tree().get_nodes_in_group("spawners")
	for spawner in spawners:
		if spawner.has_method("force_spawn_for_boss"):
			var new_mites = await spawner.force_spawn_for_boss(mites_per_wave)
			current_mites.append_array(new_mites)
	
	current_state = State.IDLE
	anim.play("idle")

func check_minions():
	if is_transitioning: return 
	
	current_mites = current_mites.filter(func(m): return is_instance_valid(m))
	var enemy_count = get_tree().get_nodes_in_group("enemy").size()
	
	if current_mites.size() == 0 or enemy_count <= 1:
		is_transitioning = true 
		break_shield()

func break_shield():
	is_invincible = false
	shield_hitbox.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(shield_visual, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): shield_visual.hide())
	
	# 50/50 chance to either Hunt or Shoot Chaos Fireballs
	if randf() > 0.5:
		start_fireball_phase()
	else:
		start_hunt_phase()
func start_fireball_phase():
	current_state = State.FIREBALL
	velocity = Vector2.ZERO # Rory stays still to focus on the spell
	anim.play("summon") 
	
	print("Chaos Fireball Phase Started!")
	
	# Start a timer for the total duration (7.6 seconds)
	var end_time = Time.get_ticks_msec() + (hunt_duration * 1000)
	
	while Time.get_ticks_msec() < end_time:
		# If the boss dies mid-attack, stop the loop
		if not is_instance_valid(self): break
		
		shoot_random_fireball()
		
		# --- PHASE 2 LOGIC ---
		# Normal: 0.2 to 0.5 seconds
		# Phase 2: 0.1 to 0.25 seconds (Twice as fast!)
		var min_wait = 0.2
		var max_wait = 0.5
		
		if is_phase_2:
			min_wait *= phase_2_fire_rate
			max_wait *= phase_2_fire_rate
			
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout
	
	if is_instance_valid(self):
		start_cooldown_phase()

func shoot_random_fireball():
	var f = fireball_scene.instantiate()
	get_parent().add_child(f)
	f.global_position = global_position
	
	var random_angle = randf_range(0, TAU)
	f.direction = Vector2.RIGHT.rotated(random_angle)
	
	# Phase 2 Fireballs are faster and orange
	if "speed" in f:
		var base_speed = randf_range(200, 450)
		f.speed = base_speed * (1.5 if is_phase_2 else 1.0)
	
	if is_phase_2:
		f.modulate = Color(2, 1, 0) # Glow orange
func start_hunt_phase():
	current_state = State.HUNTING
	anim.play("walk")
	
	# If in Phase 2, move faster
	var temp_speed = move_speed
	if is_phase_2:
		move_speed *= phase_2_speed_mult
		
	await get_tree().create_timer(hunt_duration).timeout
	
	# Reset speed after hunt so it doesn't stack forever
	move_speed = temp_speed 
	start_cooldown_phase()

func start_cooldown_phase():
	current_state = State.COOLDOWN
	velocity = Vector2.ZERO
	anim.play("idle")
	await get_tree().create_timer(cooldown_duration).timeout
	recharge_shield()

func recharge_shield():
	is_invincible = true
	shield_visual.show()
	var tween = create_tween()
	tween.tween_property(shield_visual, "modulate:a", 1.0, 0.5)
	shield_hitbox.set_deferred("disabled", false)
	
	await trigger_summon_wave()
	is_transitioning = false 

func _on_bite_area_body_entered(body):
	if current_state == State.HUNTING and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
			var knockback = (body.global_position - global_position).normalized() * 500
			if "velocity" in body: body.velocity = knockback
func enter_phase_2():
	if is_phase_2: return 
	is_phase_2 = true
	
	print("PHASE 2: THE KING GROWS!")
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Instead of setting scale to 1.2, we multiply his CURRENT scale by 1.5
	var target_scale = self.scale * 1.2
	
	tween.tween_property(anim, "modulate", Color(2, 0.5, 0.5), 1.0)
	tween.tween_property(self, "scale", target_scale, 1.0)
	
	# Shake the screen more because he's heavy now
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(20.0)
