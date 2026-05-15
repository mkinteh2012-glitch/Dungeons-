extends Node2D
#Lowkey was confused AI helpd with this stuff
@export var damage := 25
@export var cooldown := 0.3
@export var attack_range := 32.0 

var owner_player: CharacterBody2D
var can_attack := true
@onready var player = get_tree().get_first_node_in_group("player")
@onready var damage_boost_ref = player.damage_boost

@onready var hitbox = $Hitbox 
@onready var impact_sound = $Hit

func _ready():
	hitbox.monitoring = false		
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node2D):
	if hitbox.monitoring and body.is_in_group("enemy"):

		if impact_sound:
	
			impact_sound.pitch_scale = randf_range(1.1, 1.5)
			impact_sound.play()
		

		

		var damage_boost_ref = player.damage_boost
		var final_damage = damage + damage_boost_ref
		if player and player.get("is_weakened") == true:
			final_damage = ceil(damage / 2.0)
			print("Dagger Weakened Hit: ", final_damage)
		else:
			print("Dagger Full Hit: ", final_damage)
		
		player.spawn_wave()


		if body.has_method("take_damage"):
			body.take_damage(final_damage)
		elif body.has_node("Health"):
			body.get_node("Health").take_damage(final_damage)
			

		var tw = create_tween()
		body.modulate = Color(10, 10, 10) # Flash bright
		tw.tween_property(body, "modulate", Color(1, 1, 1), 0.1)
			

		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(2.0)

func attack(_direction: Vector2):
	if not can_attack: return
	can_attack = false

	# 1. LUNGE OUT
	# We turn the hitbox ON immediately
	hitbox.monitoring = true
	
	var tween = create_tween()
	# Move to the far range quickly
	tween.tween_property(self, "position", Vector2(0, -32), 0.05)
	
	# Wait at the tip for a split second (The "Apex")
	await get_tree().create_timer(0.05).timeout
	
	# We DO NOT turn monitoring off yet.
	var return_tween = create_tween()
	# Move back to the held position slightly slower than the lunge
	return_tween.tween_property(self, "position", Vector2(0, -12), 0.1)
	
	# Wait for the return move to finish
	await return_tween.finished
	
	# 3. RESET
	# Now that it's back at the player's hand, it's safe to turn off
	hitbox.monitoring = false
	
	# Cooldown before the next stab
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
