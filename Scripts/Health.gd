extends Node

signal died
signal health_changed(current_health)

@export var max_health := 3        # 3 hearts
var current_health := max_health

func _ready():
	current_health = max_health

func take_damage(amount := 0.5):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)

	emit_signal("health_changed", current_health)

	if current_health <= 0:
		emit_signal("died")
