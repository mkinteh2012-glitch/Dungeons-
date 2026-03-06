extends Node2D

@export var damage := 25
@export var cooldown := 0.3
@export var attack_range := 16 

var owner_player: CharacterBody2D
var can_attack := true

@onready var hitbox = $Hitbox # Ensure this Area2D has a CollisionShape2D child

func _ready():
	if not hitbox:
		push_error("Dagger needs an Area2D node named 'Hitbox'")
	hitbox.monitoring = false

func attack(direction: Vector2):
	if not can_attack or not owner_player:
		return

	can_attack = false

	# 1. Position and Rotate
	global_position = owner_player.global_position + direction.normalized() * attack_range
	rotation = direction.angle() + deg_to_rad(90)

	# 2. Enable Hitbox
	hitbox.monitoring = true
	
	# Wait for the next physics frame to ensure overlap is detected
	await get_tree().process_frame 

	# 3. Detect and Damage
	for body in hitbox.get_overlapping_bodies():
		# Check if the body has a take_damage method and isn't the player
		if body != owner_player and body.has_method("take_damage"):
			body.take_damage(damage)
			

	# 4. Disable Hitbox and wait for cooldown
	hitbox.monitoring = false
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
