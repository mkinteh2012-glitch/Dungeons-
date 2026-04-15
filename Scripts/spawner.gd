extends StaticBody2D

# --- Configuration ---
@export var group_name := "enemy"
@export var max_health := 500

@onready var spawn_sfx = $SpawnSound
@onready var low_sfx = $LowHealthSound
@onready var timer = $Timer
@onready var portal = $Portal

var health := 750
var has_spawned_halfway_wave := false 
var is_flickering := false 

var spawn_table = {
	"res://Sprites/Enemy/boomkin.tscn": 18, 
	"res://Sprites/Enemy/Vex.tscn": 12, 
	"res://Sprites/Enemy/skitter.tscn": 5, 
	"res://Sprites/Enemy/Peon.tscn": 65
}

var on_screen_limit = 30
var spawn_amount = 5
var spawn_cooldown = 15.0     

func _ready():
	health = max_health
	timer.wait_time = spawn_cooldown
	timer.one_shot = false
	
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
		print("Successfully connected Timer signal!")
	
	timer.start()
	
	# Initial spawn sequence
	trigger_spawn_sequence(spawn_amount)

func _process(delta):
	if Engine.get_frames_drawn() % 60 == 0:
		var time_left = snapped(timer.time_left, 0.1)
		var enemies_alive = get_tree().get_nodes_in_group(group_name).size()
		print("WAVE IN: ", time_left, "s | ENEMIES ALIVE: ", enemies_alive)

	if portal:
		portal.rotation += 3.0 * delta
		# Normal flickering logic (Only active below 50% health)
		if is_flickering:
			portal.visible = randf() > 0.5
			# If we aren't currently in a "Spawn Flash", use these colors
			if portal.modulate.r < 1.5: 
				portal.modulate = Color(2, 2, 2, 1) if portal.visible else Color(1, 1, 1, 1)

func take_damage(amount: int):
	health -= amount
	if health <= (max_health / 2) and not has_spawned_halfway_wave:
		has_spawned_halfway_wave = true
		is_flickering = true 
		low_sfx.play()
		trigger_spawn_sequence(7) # Emergency wave
		reset_spawn_timer() 
	
	if health <= 0:
		die()

func die():
	queue_free()

func reset_spawn_timer():
	timer.stop()
	timer.start() 

func _on_timer_timeout():
	trigger_spawn_sequence(spawn_amount)

# --- NEW: The Sequence (Flash -> Sound -> Wait -> Spawn) ---
func trigger_spawn_sequence(amount: int):
	print("PREPARING SPAWN...")
	
	# 1. VISUAL FLASH: Make portal turn bright white
	var flash_tween = create_tween()
	# Set to 5,5,5 to make it extremely bright (Glow effect)
	flash_tween.tween_property(portal, "modulate", Color(5, 5, 5, 1), 0.2) 
	
	# 2. AUDIO: Play the spawn sound
	spawn_sfx.play()
	
	# 3. WAIT: 1 Second delay
	await get_tree().create_timer(1.0).timeout
	
	# 4. RESET COLOR: Fade back to normal
	var fade_tween = create_tween()
	fade_tween.tween_property(portal, "modulate", Color(1, 1, 1, 1), 0.4)
	
	# 5. SPAWN: Finally bring the enemies in
	spawn_group(amount)

func spawn_group(amount: int):
	for i in range(amount):
		var live_enemies = get_tree().get_nodes_in_group(group_name)
		if live_enemies.size() < on_screen_limit:
			var chosen_path = pick_random_path()
			var enemy_scene = load(chosen_path)
			
			if enemy_scene:
				var enemy_instance = enemy_scene.instantiate()
				var random_offset = Vector2(randf_range(-25, 25), randf_range(-25, 25))
				enemy_instance.global_position = global_position + random_offset
				enemy_instance.rotation = 0
				
				get_parent().add_child.call_deferred(enemy_instance)
				enemy_instance.add_to_group(group_name)
				
				enemy_instance.scale = Vector2.ZERO
				var tw = create_tween()
				tw.tween_property(enemy_instance, "scale", Vector2(1,1), 0.3).set_trans(Tween.TRANS_ELASTIC)
		else:
			break

func pick_random_path() -> String:
	var total_weight = 0
	for weight in spawn_table.values(): total_weight += weight
	var roll = randi() % total_weight
	var cursor = 0
	for path in spawn_table:
		cursor += spawn_table[path]
		if roll < cursor: return path
	return spawn_table.keys()[0]
