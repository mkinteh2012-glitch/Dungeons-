extends CharacterBody2D

# --- VARIABLES ---
@export_group("Movement Settings")
@export var speed: float = 300.0
@export var jitter_power: float = 30.0
@export var change_direction_time: float = 0.4 # How often it picks a new path

@export_group("Combat Settings")
@export var ring_scene: PackedScene # Drag your Ogre Ring .tscn here!

var current_direction: Vector2 = Vector2.ZERO
var timer: float = 0.0
var is_dying: bool = false

# --- SETUP ---
func _ready() -> void:
	pick_new_direction()
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")

# --- LOOP ---
func _physics_process(delta: float) -> void:
	if is_dying:
		return

	timer += delta
	if timer >= change_direction_time:
		pick_new_direction()
		timer = 0.0

	var collision = move_and_collide(current_direction * speed * delta)
	if collision:
		current_direction = current_direction.bounce(collision.get_normal())
		timer = 0.0

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (jitter_power / 5.0)

# --- HELPER FUNCTIONS ---
func pick_new_direction() -> void:
	var random_angle = randf_range(0, 2 * PI)
	current_direction = Vector2.RIGHT.rotated(random_angle)

func take_damage(_amount: int) -> void:
	die()

func die() -> void:
	if is_dying:
		return
	is_dying = true

	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.set_deferred("visible", false)

	await get_tree().create_timer(1.0).timeout
	
	if ring_scene:
		var ring = ring_scene.instantiate()
		ring.global_position = global_position
		ring.modulate = Color(3.5, 3.5, 0.5)
		if "growth_speed" in ring:
			ring.growth_speed = ring.growth_speed / 2.0
		get_parent().call_deferred("add_child", ring)
	
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		die()
