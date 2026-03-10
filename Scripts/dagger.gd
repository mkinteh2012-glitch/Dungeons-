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

	# 1. Position the Dagger
	# We use global_position to ensure it stays where the player swung
	global_position = owner_player.global_position + direction.normalized() * attack_range
	rotation = direction.angle()

	# 2. Wake up the Hitbox
	hitbox.monitoring = true
	
	# 3. Give the Physics Engine time to "feel" the overlap
	# We wait 0.1 seconds (the duration of your swing/lunge)
	await get_tree().create_timer(0.1).timeout

	# 4. Check what we hit
	var bodies = hitbox.get_overlapping_bodies()
	
	# Check the 'Output' console for this message!
	print("Dagger hit: ", bodies) 

	for body in bodies:
		if body.has_method("take_damage") and body != owner_player:
			body.take_damage(damage)

	# 5. Cleanup
	hitbox.monitoring = false
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
