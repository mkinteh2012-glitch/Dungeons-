extends Area2D

@export var coin_value: int = 1

func _ready():
	# Give it a golden glow or a little bounce
	var tween = create_tween().set_loops()
	$AnimatedSprite2D.play("default")
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(1.0, 1.0), 0.5)

func _on_body_entered(body):
	if body.is_in_group("player"):
			GameStats.add_coins(1)
			queue_free()
