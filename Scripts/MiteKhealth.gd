extends Node

signal died

@export var max_health := 1500
@onready var health := max_health # Sets health to 10 immediately

func take_damage(amount: int):
	var boss = get_parent()
	
	if "is_invincible" in boss:
		if boss.is_invincible:
			print("HIT BLOCKED: Shield is still active!")
			return 

	health -= amount
	# Fix: Use the variable you already defined at the top
	if get_parent().has_node("Health_Bar"):
		get_parent().get_node("Health_Bar").update_health(health, max_health)
	
	print("KING HIT: Remaining health: ", health)
	if health <= (max_health / 2):
		if boss.has_method("enter_phase_2"):
			boss.enter_phase_2()
	
	# --- EVERYTHING BELOW THIS ONLY HAPPENS ON DEATH ---
	if health <= 0:
		print("BOSS DEFEATED: Starting cleanup...")
		
		# 1. Music and Visuals
		var music = get_tree().current_scene.get_node_or_null("RoryMusicManager")
		if music:
			music._play_victory()
			
		boss.visible = false 
		boss.set_collision_layer_value(1, false) 
		boss.set_collision_mask_value(1, false)
		boss.process_mode = Node.PROCESS_MODE_DISABLED
		
		# 2. Kill minions
		var minions = get_tree().get_nodes_in_group("enemy")
		for m in minions:
			m.queue_free()
	
		# 3. Camera Shake
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("apply_shake"):
			cam.apply_shake(12.0)

		# 4. The Poof Logic
		var poof = boss.get_node_or_null("DeathPoof")
		if poof:
			var level = get_tree().current_scene
			var rory_pos = boss.global_position
			poof.get_parent().remove_child(poof)
			level.add_child(poof)
			poof.global_position = rory_pos
			poof.emitting = true
			
			var cleanup_tween = get_tree().create_tween()
			cleanup_tween.tween_interval(1.5)
			cleanup_tween.tween_callback(poof.queue_free)
		
		# 5. Final Delete
		await get_tree().create_timer(5).timeout
		boss.queue_free()
