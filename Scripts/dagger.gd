extends Node2D

@export var damage := 25
@export var cooldown := 0.3
@export var attack_range := 32.0 

var owner_player: CharacterBody2D
var can_attack := true

@onready var hitbox = $Hitbox 

func _ready():
	hitbox.monitoring = false
	# Connect the signal so it triggers every time it touches something NEW
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _on_hitbox_body_entered(body: Node2D):

	if hitbox.monitoring and body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
			
			var cam = get_viewport().get_camera_2d()
			if cam and cam.has_method("apply_shake"):
				cam.apply_shake(2.0)

func attack(_direction: Vector2):
	if not can_attack: return
	can_attack = false

	# 1. Lunge out
	# Since your sprite is drawn UP, we move it on the Y axis 
	# (Negative Y is Up in Godot)
	position = Vector2(0, -32) 
	hitbox.monitoring = true
	
	await get_tree().create_timer(0.1).timeout
	
	# 2. RESET to the "Held" position
	hitbox.monitoring = false
	position = Vector2(0, -12) 
	
	await get_tree().create_timer(cooldown).timeout
	can_attack = true
