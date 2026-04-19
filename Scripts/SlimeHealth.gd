extends Node

signal died

@export var max_health := 100
var health := 100

func _ready():
	health = max_health
	
func take_damage(amount: int):
	health -= amount
	print("Enemy health: ", health)
	
	if health <= 0:
		# 1. Camera Shake
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(2.0)

		# 2. The Poof Logic
		var poof = get_parent().get_node_or_null("DeathPoof")
		if poof:
			# Move to level root so it survives
			var level = get_tree().current_scene
			poof.get_parent().remove_child(poof)
			level.add_child(poof)
			
			poof.global_position = get_parent().global_position
			poof.z_index = 100
			poof.emitting = true
			
			# USE A TWEEN FOR CLEANUP (Avoids the Lambda Error)
			var cleanup_tween = get_tree().create_tween()
			cleanup_tween.tween_interval(1.5) # Wait 1.5 seconds
			cleanup_tween.tween_callback(poof.queue_free)
		
		# 3. Final Signal
		died.emit()		
