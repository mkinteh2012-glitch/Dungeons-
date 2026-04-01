extends Node

signal died

@export var max_health := 25
# This line is what the Peon is looking for:
var current_health: int

func _ready():
	current_health = max_health
	
func take_damage(amount: int):
	# FIX: Changed 'health' to 'current_health'
	current_health -= amount
	print("Enemy health: ", current_health)
	
	# FIX: Changed 'health' to 'current_health'
	if current_health <= 0:
		# 1. Camera Shake
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(6.0)

		# 2. The Poof Logic
		var poof = get_parent().get_node_or_null("DeathPoof")
		if poof:
			# Move to level root so it survives
			var level = get_tree().current_scene
			var global_pos = get_parent().global_position # Save pos before removing
			
			poof.get_parent().remove_child(poof)
			level.add_child(poof)
			
			poof.global_position = global_pos
			poof.z_index = 100
			poof.emitting = true
			
			# TWEEN FOR CLEANUP
			var cleanup_tween = get_tree().create_tween()
			cleanup_tween.tween_interval(1.5)
			cleanup_tween.tween_callback(poof.queue_free)
		
		# 3. Final Signal
		died.emit()
