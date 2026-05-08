extends CharacterBody2D

signal badge_destroyed(type)

@export var health: int = 750
var badge_type: String = "fire" # Default

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	add_to_group("BossBadges")
	# Set metadata here just to be safe
	set_meta("bossbadge", true)

# The Boss calls this right after instantiating
func setup_badge(type: String):
	badge_type = type
	
	# We wait for the sprite to be ready if it's not yet
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
	
	if health <= 0:
		_notify_boss_and_die()

func _notify_boss_and_die():
	badge_destroyed.emit(badge_type)
	for node in get_tree().get_nodes_in_group("BossGroup"):
		if node.has_meta("finalboss"):
			node._on_badge_destroyed(badge_type)
			break
	queue_free()

func get_badge_type() -> String:
	return badge_type
