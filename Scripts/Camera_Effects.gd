extends Camera2D

var shake_strength := 0.0
var fade_speed := 5.0

func _process(delta):
	if shake_strength > 0:

		shake_strength = lerp(shake_strength, 0.0, fade_speed * delta)

		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		offset = Vector2.ZERO

func apply_shake(strength: float):
	shake_strength = strength
