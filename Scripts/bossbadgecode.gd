extends Area2D

signal badge_destroyed(type)

@export_enum("fire", "poison", "electric", "bomb") var badge_type: String = "fire"
@export var health: int = 20

@onready var sprite = $AnimatedSprite2D

func _ready():
	# Automatically play the correct animation based on the type set in Inspector
	if sprite:
		sprite.play(badge_type)


func take_damage(amount: int):
	health -= amount
	
	# Hit Flash Animation
	var t = get_tree().create_tween()
	t.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	t.tween_property(self, "modulate", Color.WHITE, 0.05)
	
	# Little "juice" effect: scale down and back up when hit
	t.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.05)
	t.tween_property(self, "scale", Vector2(1, 1), 0.05)

	if health <= 0:
		_die()

func _die():
	badge_destroyed.emit(badge_type)
	# You could play a "death" animation here before queue_free
	queue_free()
