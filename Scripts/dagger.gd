extends Node2D

@export var damage := 25
@export var cooldown := 0.3
@export var attack_range := 32.0 

var owner_player: CharacterBody2D
var can_attack := true

@onready var hitbox = $Hitbox 

func _ready():
	hitbox.monitoring = false
	# We use area_entered if your enemy hitboxes are Areas, 
	# or body_entered if they are CharacterBodies.
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node2D):
	if hitbox.monitoring and body.is_in_group("enemies"):
		# 1. Find the player globally since Dagger isn't a child
		var player = get_tree().get_first_node_in_group("player")
		
		# 2. Calculate Damage
		var final_damage = damage
		
		# Check if player exists and if they are currently weakened
		if player and player.get("is_weakened") == true:
			final_damage = ceil(damage / 2.0)
			print("Dagger detected Player Weakness! Dealing: ", final_damage)
		else:
			print("Dagger dealing FULL damage: ", final_damage)

		# 3. Apply Damage to Enemy
		if body.has_method("take_damage"):
			body.take_damage(final_damage)
		elif body.has_node("Health"):
			body.get_node("Health").take_damage(final_damage)
			
		# 4. Effects
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(2.0)
func attack(_direction: Vector2):
	if not can_attack: return
	can_attack = false

	# 1. Lunge out
	position = Vector2(0, -32) 
	hitbox.monitoring = true
	
	await get_tree().create_timer(0.1).timeout
	
	# 2. RESET to the "Held" position
	hitbox.monitoring = false
	position = Vector2(0, -12) 
	
	await get_tree().create_timer(cooldown).timeout
	can_attack = true	
