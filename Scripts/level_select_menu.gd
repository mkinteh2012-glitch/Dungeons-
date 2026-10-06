extends Control

@export var card_scene: PackedScene
@onready var list = $VBoxContainer
@onready var floor_label = $CanvasLayer/FloorDisplay

# --- SHOP STUFF ---
@onready var shop_menu = $UpgradeMenu
@onready var shop_button = $ShopButtom

# --- CONFIG / SETTINGS ---
@export var IS_DEBUG: bool = false
@export var scroll_speed: float = 600.0 # Speed of arrow key scrolling

# --- SCROLL MEMORY ---
var initial_list_y: float = 0.0

func _ready() -> void:
	print("--- LEVEL SELECT READY (DEBUG MODE: ", IS_DEBUG, ") ---")
	GameStats.level_in_progress = false
	
	var master_bus_index = AudioServer.get_bus_index("SFX")
	if master_bus_index != -1:
		AudioServer.set_bus_mute(master_bus_index, false)
	
	update_floor_display()
	
	if shop_menu:
		shop_menu.visible = false
	
	# Remember the starting vertical position of the list
	if list:
		initial_list_y = list.position.y
	
	refresh_level_list()

func _process(delta: float) -> void:
	# Scroll the VBoxContainer up/down directly using arrow keys
	if list and list.visible:
		if Input.is_key_pressed(KEY_DOWN):
			list.position.y -= scroll_speed * delta
		elif Input.is_key_pressed(KEY_UP):
			list.position.y += scroll_speed * delta
			
		# Prevent scrolling too far up past the original position
		if list.position.y > initial_list_y:
			list.position.y = initial_list_y

func _input(event: InputEvent) -> void:
	# Press F1 at runtime to toggle Debug Mode on/off
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		IS_DEBUG = !IS_DEBUG
		print("[DEBUG] Switched IS_DEBUG to: ", IS_DEBUG)
		refresh_level_list()

func refresh_level_list() -> void:
	if list == null or card_scene == null:
		return

	# Reset list position back to top when refreshing
	list.position.y = initial_list_y

	# Clear previous level cards
	for child in list.get_children():
		child.queue_free()

	# Load levels based on debug status
	if IS_DEBUG:
		load_all_stages_cheat()
	else:
		load_normal_floor_levels()

# --- NORMAL GAMEPLAY LEVEL LOADING ---
func load_normal_floor_levels() -> void:
	var path_to_load = ""
	var current_floor = GameStats.current_floor
	
	if current_floor == 15:
		# FINAL BOSS FLOOR
		print("STATUS: FINAL BOSS ENCOUNTER!")
		create_card_from_level("res://Levels/Boss/Final/FinalFight.tscn")
		return
	elif current_floor == 5 or current_floor == 10:
		# RANDOM BOSS FLOOR
		print("STATUS: Random Boss Encounter!")
		path_to_load = "res://levels/boss/"
	else:
		# NORMAL LEVEL FLOOR
		path_to_load = "res://levels/"

	load_all_levels(path_to_load)

func load_all_levels(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		print("ERROR: Could not open directory! ", path)
		return

	dir.list_dir_begin()
	var file_names: Array[String] = []
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap"):
				file_names.append(file_name.replace(".remap", ""))
		file_name = dir.get_next()
	
	# Boss recycling logic
	if "boss" in path:
		if Global.used_bosses.size() >= file_names.size():
			Global.used_bosses.clear()
	
	file_names.shuffle()

	# Pick 3 levels (or bosses)
	var levels_added = 0
	for f in file_names:
		if levels_added >= 3:
			break
		
		var full_path = path + f
		
		# Prevent fighting the same random boss twice in one run
		if "boss" in path and Global.used_bosses.has(full_path):
			continue
			
		create_card_from_level(full_path)
		levels_added += 1

# --- DEBUG CHEAT LEVEL LOADING ---
func load_all_stages_cheat() -> void:
	var all_levels = scan_folder_for_levels("res://levels/")
	for path in all_levels:
		create_card_from_level(path)

func scan_folder_for_levels(path: String) -> Array[String]:
	var results: Array[String] = []
	var dir = DirAccess.open(path)
	if not dir:
		return results

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			results.append_array(scan_folder_for_levels(path + file_name + "/"))
		elif file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap"):
			results.append((path + file_name).replace(".remap", ""))
		file_name = dir.get_next()
		
	return results

# --- CARD CREATION ---
func create_card_from_level(path: String) -> void:
	var level_scene = load(path)
	if not level_scene:
		return
	
	var temp_node = level_scene.instantiate()
	var new_card = card_scene.instantiate()
	list.add_child(new_card)
	
	var diff_raw = temp_node.get("level_difficulty")
	var diff = str(diff_raw).to_lower() if diff_raw else "normal"
	
	# Color coding
	var color_easy = Color(0.3, 0.36, 0.94)
	var color_boss = Color(0.35, 0.02, 0.35)
	
	var weight := 0.3
	match diff:
		"easy": weight = 0.0
		"normal": weight = 0.2
		"hard": weight = 0.5
		"boss": weight = 0.8
		"?????????": weight = 1.0
	
	new_card.modulate = color_easy.lerp(color_boss, weight)
	
	new_card.setup({
		"name": temp_node.get("level_name") if temp_node.has_method("get") and temp_node.get("level_name") else path.get_file().get_basename(),
		"reward": temp_node.get("level_reward") if temp_node.has_method("get") and temp_node.get("level_reward") else 0,
		"difficulty": diff.capitalize(),
		"path": path
	})
	
	temp_node.queue_free()

func update_floor_display() -> void:
	if floor_label:
		floor_label.text = "FLOOR: " + str(GameStats.current_floor)

# --- BUTTON HANDLERS ---
func _on_shop_buttom_pressed() -> void:
	# CHEAT: Grant currency and max upgrades only if in Debug Mode
	if IS_DEBUG:
		if "gold" in GameStats:
			GameStats.gold += 99999
		if "money" in GameStats:
			GameStats.money += 99999
		if "coins" in GameStats:
			GameStats.coins += 99999
			
		if GameStats.has_method("max_all_upgrades"):
			GameStats.max_all_upgrades()
		
		print("[DEBUG] Max currency & upgrades granted!")

	if shop_menu == null:
		return
		
	shop_menu.visible = !shop_menu.visible
	
	if shop_menu.visible:
		shop_button.text = "Levels"
		list.visible = false
		if shop_menu.has_method("refresh_shop"):
			shop_menu.refresh_shop()
	else:
		shop_button.text = "Shop"
		list.visible = true

func _on_upgrade_menu_hidden() -> void:
	list.visible = true
