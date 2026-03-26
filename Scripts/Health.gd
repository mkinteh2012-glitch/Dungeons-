extends Node

signal died
signal health_changed(new_health)

@export var max_health: int = 6
@onready var sprite = get_parent().get_node("AnimatedSprite2D")
var current_health: int = 0
var is_invincible := false

func _ready():
	current_health = max_health
	health_changed.emit(current_health)

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO):

	if is_invincible:
		return


	is_invincible = true
	
	current_health -= amount
	current_health = clampi(current_health, 0, max_health)
	health_changed.emit(current_health)
	

	var player = get_parent()
	if player.has_method("handle_hit"):
		player.handle_hit(source_pos)
	
	if current_health <= 0:
		died.emit()
		return


	await get_tree().create_timer(1.0).timeout
	is_invincible = false
