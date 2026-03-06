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
	health.died.connect(_on_died)
	
	current_weapon = dagger_scene.instantiate()
	weapon_holder.add_child(current_weapon)
	
	var timer = Timer.new()
	timer.name = "AttackTimer"
	timer.wait_time = attack_cooldown
	timer.one_shot = true
	timer.timeout.connect(_on_attack_timer_timeout)
	add_child(timer)

func _physics_process(_delta):
	# 1. Handle Lunge Movement
	if is_lunging:
		# We use move_and_slide() here too, which prevents clipping through walls
		move_and_slide()
		return # Skip normal movement input while lunging

	# 2. Normal Movement Input
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector.length() > 0:
		facing_direction = input_vector
		velocity = input_vector * speed
		sprite.play("Run")
		sprite.flip_h = velocity.x < 0
		
		if weapon_holder is Node2D:
			weapon_holder.rotation = facing_direction.angle()
	else:
		velocity = Vector2.ZERO
		sprite.play("Idle")

	move_and_slide()

func _process(_delta):
	if Input.is_action_just_pressed("attack") and can_attack:
		attack()

func attack():
	can_attack = false
	is_lunging = true
	
	# Apply the lunge velocity
	velocity = facing_direction * lunge_force
	
	current_weapon.attack(facing_direction)
	$AttackTimer.start()
	
	# Create a quick timer to stop the lunge
	await get_tree().create_timer(lunge_duration).timeout
	is_lunging = false

func _on_attack_timer_timeout():
	can_attack = true

func _on_died():
	get_tree().reload_current_scene()	
