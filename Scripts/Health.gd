extends Node

signal died
signal health_changed(new_health)

var regen_timer: float = 0.0
const REGEN_WAIT_TIME: float = 20.0

# --- UPDATED HEALTH LOGIC ---
@export var base_max_health: int = 6  # Your original starting health
var max_health: int = 6              # This will be calculated dynamically
var nor_max_health: int = 6  # Kept this to stop the error
@onready var sprite = get_parent().get_node_or_null("AnimatedSprite2D")

var current_health: int = 0:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health)
		sync_health_to_ui()
		
		if current_health <= 0:	
			get_tree().create_timer(1.0).timeout.connect(func(): died.emit())

var is_invincible := false

func _ready():
	# 1. Calculate the new max health based on the shop level
	var health_level = GameStats.ability_levels.get("health", 0)
	
	# Formula: Starting health (6) + 2 extra hearts per level
	max_health = base_max_health + (health_level * 2)
	
	# 2. Start the player at full (upgraded) health
	current_health = max_health
	
	sync_health_to_ui()
	
func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if is_invincible or current_health <= 0:
		return

	regen_timer = 0.0 
	is_invincible = true
	current_health -= amount
	sync_health_to_ui()
	var player = get_parent()
	if player.has_method("handle_hit"):
		player.handle_hit(source_pos)
	
	if current_health > 0:
		get_tree().create_timer(1.0).timeout.connect(func(): is_invincible = false)
		
func play_regen_flash():
	# 1. Play the sound safely
	var healsound = get_node_or_null("HealSound")
	if healsound:
		healsound.play()
	
	# 2. Handle the visual flash
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.GREEN, 0.1)
		
		var player = get_parent()
		var target_color = Color.WHITE
		
		# Check for weakened state color
		if "is_weakened" in player and player.is_weakened:
			target_color = Color(0.7, 0.2, 0.9, 1.0)
			
		tween.tween_property(sprite, "modulate", target_color, 0.2)
func heal(amount):
	current_health += amount
	# Make sure you don't go over max health
	current_health = min(current_health, max_health) 
	
func sync_health_to_ui():
	# 1. Look for the HUD in the game scene
	# We use find_child so it works even if the HUD is deep in the tree
	
	var hud = get_tree().current_scene.find_child("heart_gui", true, false)
	if hud:
		# 2. Send the player's variables to the HUD's function
		hud.update_hearts(current_health, max_health)
	else:
		print("Error: Could not find the heart_gui!")
