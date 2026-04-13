extends Node

signal died
signal health_changed(new_health)

var regen_timer: float = 0.0
const REGEN_WAIT_TIME: float = 20.0

@export var max_health: int = 6
@onready var sprite = get_parent().get_node_or_null("AnimatedSprite2D")

# The 'set(value)' block below runs EVERY time current_health is changed.
# This is much more efficient than checking 60 times a second!

func _process(delta):
	# Only count if we aren't at max health
	if current_health < max_health:
		regen_timer += delta
		
		if regen_timer >= REGEN_WAIT_TIME:
			current_health += 1 # This triggers the 'set(value)' block automatically!
			regen_timer = 0.0
			print("Natural Regen: +0.5 Heart")
			play_regen_flash()
	else:
		# Reset timer if we are already full health
		regen_timer = 0.0

var current_health: int = 0:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health) # Automatically updates the bar
		
		# Check for death immediately when health hits 0
		if current_health <= 	0:	
			await get_tree().create_timer(1.0).timeout
			died.emit()

var is_invincible := false

func _ready():
	# This will trigger the 'set' block above and update your UI instantly
	current_health = max_health

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if is_invincible or current_health <= 0:
		return

	# --- THE RESET ---
	regen_timer = 0.0 
	
	is_invincible = true
	current_health -= amount
	
	var player = get_parent()
	if player.has_method("handle_hit"):
		player.handle_hit(source_pos)
	
	if current_health > 0:
		await get_tree().create_timer(1.0).timeout
		is_invincible = false
		
func play_regen_flash():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.GREEN, 0.1)
		# Checks if the player script has the 'is_weakened' variable to decide return color
		var player = get_parent()
		var target_color = Color.WHITE
		if "is_weakened" in player and player.is_weakened:
			target_color = Color(0.7, 0.2, 0.9, 1.0)
			
		tween.tween_property(sprite, "modulate", target_color, 0.2)
