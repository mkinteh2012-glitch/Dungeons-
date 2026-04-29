extends CharacterBody2D

# --- Variables ---
@export_group("Movement Settings")
@export var speed: float = 300.0
@export var jitter_power: float = 30.0
@export var change_direction_time: float = 0.4 # How often it picks a new path

@export_group("Combat Settings")
@export var ring_scene: PackedScene # Drag your Ogre Ring .tscn here!

var current_direction: Vector2 = Vector2.ZERO
var timer: float = 0.0

# --- Setup ---
func _ready():
	# Pick the first direction immediately
	pick_new_direction()
	
	# Start the animation if it exists
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

# --- Loop ---
func _physics_process(delta):
	timer += delta
	if timer >= change_direction_time:
		pick_new_direction()
		timer = 0.0

	# Move and check for collision at the same time
	var collision = move_and_collide(current_direction * speed * delta)
	
	if collision:
		# We hit a wall! Bounce off it.
		current_direction = current_direction.bounce(collision.get_normal())
		# Optional: Reset the timer so it keeps moving in the new bounce direction
		timer = 0.0

	# Visual Shaking
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (jitter_power / 5.0)

# --- Helper Functions ---
func pick_new_direction():
	# Picks a totally random angle (0 to 360 degrees)
	var random_angle = randf_range(0, 2 * PI)
	current_direction = Vector2.RIGHT.rotated(random_angle)

# Call this from your Player's Bow or Dagger script
func take_damage(_amount):
	die()

func die():
	# Spawn the electric death ring
	$AnimatedSprite2D.set_deferred("visible", false)
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout
	if ring_scene:
		var ring = ring_scene.instantiate()
		ring.global_position = global_position
		
		# Give the ring a Neon Glow (Requires WorldEnvironment)
		# Raw values over 1.0 make it glow
		ring.modulate = Color(3.5, 3.5, 0.5) 
		ring.growth_speed = ring.growth_speed/2
		get_parent().call_deferred("add_child", ring)
	
	# Delete the Spark
	queue_free()
func _on_body_entered(body):
	if body.is_in_group("player"):
		# 1. Damage the player
		if body.has_method("take_damage"):
			body.take_damage(1)
			die()
		
