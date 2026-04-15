extends Node

signal died
signal health_changed(new_health)

var regen_timer: float = 0.0
const REGEN_WAIT_TIME: float = 20.0

@export var max_health: int = 6
@onready var sprite = get_parent().get_node_or_null("AnimatedSprite2D")

var current_health: int = 0:
	set(value):
		current_health = clampi(value, 0, max_health)
		health_changed.emit(current_health)
		
		if current_health <= 0:	
			# We use a callable inside the timer to be safer
			get_tree().create_timer(1.0).timeout.connect(func(): died.emit())

var is_invincible := false

func _ready():
	current_health = max_health

func _process(delta):
	if current_health < max_health:
		regen_timer += delta
		if regen_timer >= REGEN_WAIT_TIME:
			current_health += 1 
			regen_timer = 0.0
			print("Natural Regen: +1 Heart")
			play_regen_flash()
	else:
		regen_timer = 0.0

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):
	if is_invincible or current_health <= 0:
		return

	regen_timer = 0.0 
	is_invincible = true
	current_health -= amount
	
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
