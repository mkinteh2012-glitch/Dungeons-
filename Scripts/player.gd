extends CharacterBody2D

@export var speed := 150
@export var attack_cooldown := 0.5 
@export var lunge_force := 400.0  # How fast the lunge is
@export var lunge_duration := 0.15 # How long the lunge lasts

@onready var weapon_holder = $WeaponHolder
@onready var health = $Health
@onready var sprite = $AnimatedSprite2D

var dagger_scene = preload("res://Weapons/Dagger.tscn")
var current_weapon
var facing_direction := Vector2.RIGHT
var can_attack := true
var is_lunging := false

func _ready():
	# 1. Connect health
	health.died.connect(_on_died)
	
	# 2. Setup the dagger ONCE
	current_weapon = dagger_scene.instantiate()
	current_weapon.owner_player = self
	weapon_holder.add_child(current_weapon)
	

	current_weapon.position = Vector2( 12, 0)
	
	# 3. Setup the attack timer ONCE
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = attack_cooldown
	timer.one_shot = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)
	
func _physics_process(_delta):
	if is_lunging:
		move_and_slide()
		return 

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		# 1. Normalize ensures diagonal speed isn't faster than straight speed
		facing_direction = input_vector.normalized()
		velocity = facing_direction * speed
		
		# 2. Animation logic
		sprite.play("Run")
		# Only flip if moving significantly left or right to avoid jitter
		if abs(input_vector.x) > 0.1:
			sprite.flip_h = input_vector.x < 0
		
		# 3. ROTATION (The "Walking" direction)
		if weapon_holder:
			# Use the angle of the movement vector
			# We add PI/2 (90 degrees) because your sprite faces DOWN by default
			weapon_holder.rotation = facing_direction.angle() + PI/2
	else:
		velocity = Vector2.ZERO
		sprite.play("Idle")

	move_and_slide()
func _process(_delta):
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()

# --- NEW: DAMAGE FUNCTION ---
# This is what the projectile calls when it hits the player
func take_damage(amount: int):
	if health:
		# Check if your Health node has its own take_damage function
		if health.has_method("take_damage"):
			health.take_damage(amount)
		# Otherwise, manually subtract from a variable (common if it's a basic script)
		elif "current_health" in health:
			health.current_health -= amount
			if health.current_health <= 0:
				_on_died()
		
		print("Player hit for ", amount, " damage!")

func attack():
	can_attack = false
	is_lunging = true
	
	velocity = facing_direction * lunge_force
	
	current_weapon.attack(facing_direction)
	$AttackTimer.start()
	
	await get_tree().create_timer(lunge_duration).timeout
	is_lunging = false

func _on_attack_timer_timeout():
	can_attack = true

func _on_died():
	# Resets the scene when health hits 0
	get_tree().call_deferred("reload_current_scene")
