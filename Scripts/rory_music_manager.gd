extends AudioStreamPlayer

# --- BOSS STREAMS ---
@export_group("Boss Music")
@export var main_track: AudioStream
@export var prep_stinger: AudioStream
@export var attack_stinger: AudioStream
@export var defeat_stinger: AudioStream
@export var loop_start_offset: float = 12.5 

# --- NORMAL STREAMS ---
@export_group("Normal Music")
@export var normal_louie: AudioStream
@export var near_louie: AudioStream
@export var battle_louie: AudioStream

# Settings for volumes
@export var normal_volume := 0.0
@export var boost_volume := 2.0  # Subtle 20% boost

# --- DISTANCE SETTINGS ---
@export var near_dist := 300.0
@export var battle_dist := 150.0

# --- NODES ---
var normal_player = AudioStreamPlayer.new()
var near_player = AudioStreamPlayer.new()
var battle_player = AudioStreamPlayer.new()

# --- STATE ---
var boss_node: Node2D = null
var last_state = -1 
var is_boss_mode = false
var intro_played = false
var is_banana_timing = false
var is_victory_playing = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for p in [normal_player, near_player, battle_player]:
		if not p.get_parent():
			add_child(p)
		p.volume_db = -80.0
	
	get_tree().node_added.connect(_on_scene_changed)
	reset_music_system()

func _on_scene_changed(node):
	if node == get_tree().current_scene:
		reset_music_system()

func reset_music_system():
	stop()
	stream = null
	normal_player.stop()
	near_player.stop()
	battle_player.stop()
	
	boss_node = null
	is_boss_mode = false
	intro_played = false
	is_victory_playing = false
	set_process(true)

func _process(_delta):
	if is_victory_playing: return # Block everything if we won

	# 1. BOSS DETECTION
	var bosses = get_tree().get_nodes_in_group("bosses")
	if bosses.size() > 0:
		var boss = bosses[0]
		if not is_boss_mode:
			_enter_boss_mode(boss)
		_process_boss_logic()
		return

	# 2. NORMAL DETECTION
	if is_boss_mode:
		is_boss_mode = false
		_play_victory()
		return
	
	_process_normal_logic()

func _process_normal_logic():
	if not normal_player.is_playing() and normal_louie != null:
		normal_player.stream = normal_louie
		near_player.stream = near_louie
		battle_player.stream = battle_louie
		normal_player.play(); near_player.play(); battle_player.play()

	var player = get_tree().get_first_node_in_group("player")
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	var dist = 9999.0
	if player and enemies.size() > 0:
		for e in enemies:
			if is_instance_valid(e):
				var d = player.global_position.distance_to(e.global_position)
				if d < dist: dist = d
	
	var t_norm = 0.0
	var t_near = -80.0
	var t_batt = -80.0
	
	if dist < battle_dist: t_batt = 0.0
	elif dist < near_dist: t_near = 0.0
	
	normal_player.volume_db = lerp(normal_player.volume_db, t_norm, 0.1)
	near_player.volume_db = lerp(near_player.volume_db, t_near, 0.1)
	battle_player.volume_db = lerp(battle_player.volume_db, t_batt, 0.1)

func _enter_boss_mode(boss):
	is_boss_mode = true
	boss_node = boss
	normal_player.stop()
	near_player.stop()
	battle_player.stop()
	_start_battle_music()

func _process_boss_logic():
	if is_banana_timing or not is_instance_valid(boss_node): return
	if boss_node.current_state != last_state:
		last_state = boss_node.current_state
		_on_boss_state_changed(last_state)

func _on_boss_state_changed(state):
	match state:
		1, 5: _switch_to_stinger(prep_stinger)
		2: _switch_to_stinger(attack_stinger)
		4: _play_banana_attack()
		0, 3: _return_to_main()


func _start_battle_music():
	stream = main_track
	
	if not intro_played:
		# FIRST 5 SECONDS: Slight boost
		volume_db = boost_volume
		play(0.0)
		intro_played = true
		
		# Create a timer to return to normal volume
		var t = get_tree().create_timer(5.0)
		t.timeout.connect(func(): 
			# Only lower if we aren't currently playing a loud stinger
			if stream == main_track:
				var tween = create_tween()
				tween.tween_property(self, "volume_db", normal_volume, 1.0)
		)
	else:
		# Subsequent loop starts
		volume_db = normal_volume
		play(loop_start_offset)

func _switch_to_stinger(stg):
	if stg == null or stream == stg: return
	
	# Prep and Attack get the 20% boost
	if stg == prep_stinger or stg == attack_stinger:
		volume_db = boost_volume
	else:
		volume_db = normal_volume
		
	stream = stg
	play()

func _return_to_main():
	if stream == main_track: return
	
	# Smoothly return to normal volume
	var tween = create_tween()
	tween.tween_property(self, "volume_db", normal_volume, 0.5)
	
	stream = main_track
	play(loop_start_offset)
	
func _play_banana_attack():
	is_banana_timing = true
	_switch_to_stinger(attack_stinger)
	await get_tree().create_timer(7.6).timeout
	is_banana_timing = false
	if is_instance_valid(boss_node): _on_boss_state_changed(boss_node.current_state)

func _play_victory():
	is_victory_playing = true
	stop()
	stream = defeat_stinger
	play()

func play_level_cleared():
	is_victory_playing = true
	normal_player.stop()
	near_player.stop()
	battle_player.stop()
	
	stop()
	# Using the specific file from your logs
	var win_sfx = load("res://Music/SFX/072 Got an Important Treasure!.mp3")
	if win_sfx:
		stream = win_sfx
		if stream is AudioStreamMP3: stream.loop = false
		play()
