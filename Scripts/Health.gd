extends Node

signal died
signal health_changed(new_health)

@export var max_health: int = 6
@onready var sprite = get_parent().get_node_or_null("AnimatedSprite2D")

# The 'set(value)' block below runs EVERY time current_health is changed.
# This is much more efficient than checking 60 times a second!
var current_health: int = 0:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health) # Automatically updates the bar
		
		# Check for death immediately when health hits 0
		if current_health <= 0:
			died.emit()

var is_invincible := false

func _ready():
	# This will trigger the 'set' block above and update your UI instantly
	current_health = max_health

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if is_invincible or current_health <= 0:
		return

	is_invincible = true
	
	# This line triggers the 'set' logic automatically
	current_health -= amount
	
	var player = get_parent()
	if player.has_method("handle_hit"):
		player.handle_hit(source_pos)
	
	# If not dead, wait for invincibility frames to expire
	if current_health > 0:
		await get_tree().create_timer(1.0).timeout
		is_invincible = false
