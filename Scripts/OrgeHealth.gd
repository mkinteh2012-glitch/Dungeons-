extends Node

signal died

@export var max_health := 50
@onready var health := max_health # Sets health to 10 immediately

func take_damage(amount):
	health -= amount

	
	
	health -= amount
	print("Enemy health: ", health)
	get_parent().get_node("Health_Bar").update_health(health, max_health)
	
	if health <= 0:
		# 1. TELL THE MUSIC TO STOP IMMEDIATELY
		# Removing from group tells the MusicManager to switch to victory
		get_parent().remove_from_group("bosses")
		
		var music = get_tree().current_scene.get_node_or_null("RoryMusicManager")
		if music:
			music._play_victory() # Call the victory function directly
			
			# 2. HIDE RORY
		var rory = get_parent() # Assuming this script is a child of Rory
		
		rory.visible = false # Makes him disappear instantly
		
		# 3. DISABLE COLLISIONS
		# This prevents the player from hitting or bumping into the "ghost"
		rory.set_collision_layer_value(1, false) 
		rory.set_collision_mask_value(1, false)
		
		# 4. STOP HIS CODE
		# This freezes his _physics_process so he stops moving/rotating
		rory.process_mode = Node.PROCESS_MODE_DISABLED
		rory.remove_from_group("bosses")	
		rory.remove_from_group("boss")
	
		
		# 2. Camera Shake
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(12.0)

		# 3. The Poof Logic
		var poof = get_parent().get_node_or_null("DeathPoof")
		if poof:
			# Get the level root (so poof survives Rory being deleted)
			var level = get_tree().current_scene
			var rory_pos = get_parent().global_position
			
			poof.get_parent().remove_child(poof)
			level.add_child(poof)
			
			poof.global_position = rory_pos
			poof.z_index = 100
			poof.emitting = true
			
			# Cleanup tween
			var cleanup_tween = get_tree().create_tween()
			cleanup_tween.tween_interval(1.5)
			cleanup_tween.tween_callback(poof.queue_free)
		await get_tree().create_timer(5).timeout
		get_parent().queue_free()	
