extends CharacterBody2D

signal badge_destroyed(type)

@export var health: int = 1000
var badge_type: String = "fire" 
var is_flickering: bool = false
var max_health: int = health

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	add_to_group("BossBadges")
	set_meta("bossbadge", true)


func setup_badge(type: String):
	badge_type = type
	

	if not is_node_ready():
		await ready
		
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation(type):
			anim_sprite.play(type)
			print("DEBUG: Badge sprite playing: ", type)
		else:
			print("ERROR: Animation '%s' not found in AnimatedSprite2D!" % type)

func take_damage(amount: int):
	health -= amount
	var t = get_tree().create_tween()
	t.tween_property(self, "modulate", Color(10, 10, 10), 0.05)
	t.tween_property(self, "modulate", Color.WHITE, 0.05)
	

	if health <= (max_health / 2.0) and not is_flickering:
		_start_low_health_flicker()
	
	
	if health <= 0:
		_notify_boss_and_die()

func _start_low_health_flicker():
	is_flickering = true
	var flicker = create_tween().set_loops()
	flicker.tween_property(self, "modulate:a", 0.3, 0.2)
	flicker.tween_property(self, "modulate:a", 1.0, 0.2)

func _notify_boss_and_die():
	badge_destroyed.emit(badge_type)
	for node in get_tree().get_nodes_in_group("BossGroup"):
		if node.has_meta("finalboss"):
			node._on_badge_destroyed(badge_type)
			break
	queue_free()

func get_badge_type() -> String:
	return badge_type
