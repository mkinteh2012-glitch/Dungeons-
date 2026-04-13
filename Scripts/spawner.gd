extends StaticBody2D

# --- Configuration ---
var spawn_table = {
	"res://Sprites/Enemy/boomkin.tscn": 20, 
	"res://Sprites/Enemy/Vex.tscn": 13, 
	"res://Sprites/Enemy/skitter.tscn": 7,
	"res://Sprites/Enemy/Peon.tscn": 60
}

var on_screen_limit = 25      
var spawn_amount = 4     
var spawn_cooldown = 18.0     

@onready var timer = $Timer
@onready var portal = $Portal

func _ready():
	# 1. Setup the Timer properties
	timer.wait_time = spawn_cooldown
	timer.one_shot = false 
	timer.autostart = true
	
	# 2. Connect the signal (using code to be safe)
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	
	timer.start()
	
	# Wait a tiny bit for the level to load, then spawn first group
	await get_tree().create_timer(0.1).timeout
	spawn_group()

func _process(delta):
	if portal:
		portal.rotation += 3.0 * delta
	
	# This prints the countdown and current count every second
	if Engine.get_frames_drawn() % 60 == 0:
		var count = get_tree().get_nodes_in_group("enemy").size()
		print("T-Minus: ", snapped(timer.time_left, 1), "s | Enemies Alive: ", count)

func _on_timer_timeout():
	# MERGED FUNCTION: This runs when the timer hits 0
	print("!!! TIMER HIT 0 - WAVE START !!!") 
	
	var live_enemies = get_tree().get_nodes_in_group("enemy")
	if live_enemies.size() < on_screen_limit:
		spawn_group()
	else:
		print("Spawn skipped: Limit is ", on_screen_limit, " but ", live_enemies.size(), " are alive.")

func spawn_group():
	for i in range(spawn_amount):
		var current_enemies = get_tree().get_nodes_in_group("enemy")
		
		if current_enemies.size() < on_screen_limit:
			var chosen_path = pick_random_path()
			var enemy_scene = load(chosen_path)
			if enemy_scene:
				spawn_enemy_instance(enemy_scene)
			
			# Small gap between individuals in the group
			await get_tree().create_timer(0.1).timeout 
		else:
			print("Wave stopped: Limit reached mid-spawn.")
			break 

func spawn_enemy_instance(scene: PackedScene):
	var enemy_instance = scene.instantiate()
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
	enemy_instance.global_position = global_position + random_offset
	
	get_parent().add_child(enemy_instance)
	
	# Make sure they are in the group so we can count them
	if not enemy_instance.is_in_group("enemy"):
		enemy_instance.add_to_group("enemy")
	
	# Pop effect
	enemy_instance.scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(enemy_instance, "scale", Vector2(1,1), 0.4).set_trans(Tween.TRANS_BACK)

func pick_random_path() -> String:
	var total_weight = 0
	for weight in spawn_table.values():
		total_weight += weight
	var roll = randi() % total_weight
	var cursor = 0
	for path in spawn_table:
		cursor += spawn_table[path]
		if roll < cursor: return path
	return spawn_table.keys()[0]	
func take_damage(amount):
		$Health.take_damage(amount)
