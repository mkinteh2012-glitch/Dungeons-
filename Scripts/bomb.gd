extends Area2D

@export var explosion_scale = 6.0 # Made bigger
@export var fuse_time = 1.0

@onready var sprite = $AnimatedSprite2D
@onready var fuse_timer = $Fusenode

var is_exploding = false

func _ready():
	fuse_timer.wait_time = fuse_time
	fuse_timer.start()
	
	# Flash red faster as time runs out
	var tween = get_tree().create_tween().set_loops(4)
	tween.tween_property(sprite, "modulate", Color(15, 1, 1), 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _on_fusenode_timeout():
	_explode()

func _explode():
	if is_exploding: return
	is_exploding = true
	
	# 1. Visual Blast
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(explosion_scale, explosion_scale), 0.15)
	tween.tween_property(self, "modulate:a", 0, 0.4)
	
	# 2. Damage Window
	# We check for hits 3 times over 0.2 seconds so it's much harder to "miss"
	for i in range(3):
		_check_for_damage()
		await get_tree().create_timer(0.05).timeout
	
	queue_free()

func _check_for_damage():
	var bodies = get_overlapping_bodies()
	for body in bodies:
			if body.has_method("take_damage"):
				body.take_damage(2)
				print("BOMB HIT PLAYER!")
	
