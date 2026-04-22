extends AudioStreamPlayer

@export var main_track: AudioStream
@export var prep_stinger: AudioStream
@export var attack_stinger: AudioStream
@export var defeat_stinger: AudioStream

@export var loop_start_offset: float = 12.5 

var boss_node: Node2D = null
var last_state = -1 
var intro_played = false
var is_banana_timing = false

func _process(_delta):
	# DETECT DEATH: If we had a boss but they are gone now
	if boss_node != null and not is_instance_valid(boss_node):
		_play_victory()
		boss_node = null # Clear it so we don't play victory repeatedly
		return

	# SEARCH FOR BOSS: If we don't have one, look for one
	if not is_instance_valid(boss_node):
		boss_node = get_tree().get_first_node_in_group("bosses")
		if is_instance_valid(boss_node):
			_start_battle_music()
			last_state = boss_node.current_state 
		else:
			if is_playing() and stream != defeat_stinger: stop()
			intro_played = false 
		return

	# IGNORE state changes if we are mid-banana-attack music
	if is_banana_timing: return

	# NORMAL STATE WATCHING
	var current_state = boss_node.current_state
	if current_state != last_state:
		_on_boss_state_changed(current_state)
		last_state = current_state

func _start_battle_music():
	if stream == main_track and is_playing(): return
	stream = main_track
	play(0.0 if not intro_played else loop_start_offset)
	intro_played = true

func _on_boss_state_changed(new_state):
	if _play_victory(): 
		return
	match new_state:
		1, 5: # Roll Prep or Moving to Center
			_switch_to_stinger(prep_stinger)
		2: # Rolling
			_switch_to_stinger(attack_stinger)
		4: # Throwing Bananas
			_play_banana_attack()
		0, 3: # Walking or Cooldown
			_return_to_main()

func _play_banana_attack():
	is_banana_timing = true
	_switch_to_stinger(attack_stinger)
	await get_tree().create_timer(7.6).timeout
	is_banana_timing = false
	if is_instance_valid(boss_node):
		_on_boss_state_changed(boss_node.current_state)
	else:
		_play_victory()

func _play_victory():
	if stream == defeat_stinger: return
	stop()
	stream = defeat_stinger
	play()
	
	

func _switch_to_stinger(stinger_stream):
	if stinger_stream == null or (stream == stinger_stream and is_playing()): return
	stream = stinger_stream
	play()

func _return_to_main():
	if stream == main_track and is_playing(): return
	stream = main_track
	play(loop_start_offset)
