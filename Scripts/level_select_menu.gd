extends Control

@export var card_scene: PackedScene
@onready var list = $VBoxContainer
@onready var floor_label = $CanvasLayer/FloorDisplay

# --- SHOP STUFF ---
@onready var shop_menu = $UpgradeMenu
@onready var shop_button = $ShopButtom 

func _ready():
	print("--- DEBUG START: LevelSelectMenu Ready ---")
	GameStats.level_in_progress = false
	var master_bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(master_bus_index, false)
	
	update_floor_display()
	
	if shop_menu:
		shop_menu.visible = false 
	
	if list == null or card_scene == null:
		return

	# Clear previous level cards
	for child in list.get_children():
		child.queue_free()

	# --- NEW BOSS SPAWN LOGIC ---
	var path_to_load = ""
	var current_floor = GameStats.current_floor
	
	if current_floor == 15:
		# FINAL BOSS FLOOR
		print("STATUS: FINAL BOSS ENCOUNTER!")
		create_card_from_level("res://Levels/Boss/Final/FinalFight.tscn")
		return # Stop here, we only want the one Final Boss card
		
	elif current_floor == 5 or current_floor == 10:
		# RANDOM BOSS FLOOR
		print("STATUS: Random Boss Encounter!")
		path_to_load = "res://levels/boss/"
	else:
		# NORMAL LEVEL FLOOR
		path_to_load = "res://levels/"

	load_all_levels(path_to_load)

func load_all_levels(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		print("ERROR: Could not open directory! ", path)
		return

	dir.list_dir_begin()
	var file_names = []
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
		if levels_added >= 3: break
		
		var full_path = path + f
		
		# Prevent fighting the same random boss twice in one run
		if "boss" in path and Global.used_bosses.has(full_path):
			continue 
			
		create_card_from_level(full_path)
		levels_added += 1

func create_card_from_level(path: String):
	var level_scene = load(path)
	if not level_scene: return
	
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
		"name": temp_node.get("level_name") if temp_node.has_method("get") and temp_node.get("level_name") else "Unknown",
		"reward": temp_node.get("level_reward") if temp_node.has_method("get") and temp_node.get("level_reward") else 0,
		"difficulty": diff.capitalize(),
		"path": path
	})
	
	temp_node.queue_free()

func update_floor_display():
	if floor_label:
		floor_label.text = "FLOOR: " + str(GameStats.current_floor)

# --- UI HANDLERS ---
func _on_shop_buttom_pressed():
	if shop_menu == null: return
	shop_menu.visible = !shop_menu.visible
	if shop_menu.visible:
		shop_button.text = "Levels"
		list.visible = false
		if shop_menu.has_method("refresh_shop"):
			shop_menu.refresh_shop()
	else:
		shop_button.text = "Shop"
		list.visible = true

func _on_upgrade_menu_hidden():
	list.visible = true
