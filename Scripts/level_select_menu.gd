extends Control

@export var card_scene: PackedScene
@onready var list = $VBoxContainer
@onready var floor_label = $CanvasLayer/FloorDisplay # Adjust path to your Label

# --- NEW STUFF ---
@onready var shop_menu = $UpgradeMenu
@onready var shop_button = $ShopButtom 
# -----------------

func _ready():
	print("--- DEBUG START: LevelSelectMenu Ready ---")
	var master_bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(master_bus_index, false)
	update_floor_display()
	if shop_menu:
		shop_menu.visible = false 
	
	if list == null:
		return

	if card_scene == null:
		return

	# Clear the UI list
	for child in list.get_children():
		child.queue_free()

	var path_to_load = ""
	if Global.levels_completed >= Global.levels_until_boss:
		path_to_load = "res://levels/boss/"
		Global.levels_completed = 0
	else:
		path_to_load = "res://levels/"

	load_all_levels(path_to_load)

func load_all_levels(path: String):
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_names = []
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap"):
				file_names.append(file_name.replace(".remap", ""))
			file_name = dir.get_next()
		
		# --- BOSS RESET LOGIC ---
		if "boss" in path:
			# Count how many boss files actually exist
			var total_boss_files = file_names.size()
			# If all bosses have been used, reset the list
			if Global.used_bosses.size() >= total_boss_files:
				print("STATUS: All bosses defeated. Resetting Boss List!")
				Global.used_bosses.clear()

		# Shuffle the entire list of found levels
		file_names.shuffle()

		# --- LIMIT TO 3 RANDOM LEVELS ---
		var random_selection = file_names.slice(0, 3)
		
		var levels_added = 0
		for f in random_selection:
			var full_path = path + f
			
			# Skip specifically if it's a boss we already fought this cycle
			if "boss" in path and Global.used_bosses.has(full_path):
				continue 
			
			create_card_from_level(full_path)
			levels_added += 1
		
		# If the filter made the list too small (e.g. only 1 boss left), 
		# we already have the reset logic above to handle the next run.

	else:
		print("ERROR: Could not open directory! ", path)

func create_card_from_level(path: String):
	var level_scene = load(path)
	if not level_scene: return
	
	var temp_node = level_scene.instantiate()
	var new_card = card_scene.instantiate()
	list.add_child(new_card)
	
	var diff_raw = temp_node.get("level_difficulty")
	var diff = str(diff_raw).to_lower() if diff_raw else "normal"
	
	var color_easy = Color(0.3, 0.36, 0.94) 
	var color_boss = Color(0.35, 0.02, 0.35) 
	
	var weight := 0.3 
	match diff:
		"easy": weight = 0.0
		"normal": weight = 0.2
		"hard": weight = 0.5
		"?????????": weight = 0.8
	
	new_card.modulate = color_easy.lerp(color_boss, weight)
	
	new_card.setup({
		"name": temp_node.get("level_name") if temp_node.get("level_name") else "Unknown",
		"reward": temp_node.get("level_reward") if temp_node.get("level_reward") else 0,
		"difficulty": diff.capitalize(),
		"path": path
	})
	
	temp_node.queue_free()

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
	
func update_floor_display():
	if floor_label:
		# Option A: Simple text
		floor_label.text = "FLOOR: " + str(GameStats.current_floor)
		
		# Option B: If using RichTextLabel for "Juicy" looks
		# floor_label.bbcode_text = "[center]FLOOR [color=yellow]" + str(GameStats.current_floor) + "[/color][/center]"
