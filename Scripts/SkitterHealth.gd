extends Node

signal died

@export var max_health := 100
var health := 100

func _ready():
	health = max_health

func take_damage(amount: int):
	health -= amount
	print("Health:", health)

	if health <= 0:
		emit_signal("died")
