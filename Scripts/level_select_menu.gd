extends Control

@export var card_scene: PackedScene
@onready var list = $VBoxContainer

func _ready():
	print("--- DEBUG START: LevelSelectMenu Ready ---")
	
	# 1. Check if the VBoxContainer exists
	if list == null:
		print("ERROR: VBoxContainer not found! Check your node path at the top of the script.")
		return
	else:
		print("SUCCESS: VBoxContainer linked correctly.")

	# 2. Check if the Card Scene is assigned in the Inspector
	if card_scene == null:
		print("ERROR: Card Scene is EMPTY! Drag ButtonMenu.tscn into the Inspector slot.")
		return

	# 3. Clear the UI list
	for child in list.get_children():
		child.queue_free()

	# 4. Determine path
	var path_to_load = ""
	if Global.levels_completed >= Global.levels_until_boss:
		path_to_load = "res://levels/boss/"
		print("STATUS: Loading BOSS levels. Current completed: ", Global.levels_completed)
		Global.levels_completed = 0
	else:
		path_to_load = "res://levels/"
		print("STATUS: Loading NORMAL levels. Current completed: ", Global.levels_completed)

	load_all_levels(path_to_load)

func load_all_levels(path: String):
	print("DEBUG: Opening directory: ", path)
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_names = []
		var file_name = dir.get_next()
		
		while file_name != "":
			# Print every file found to see what the extension actually is
			print("Found file: ", file_name)
			
			if file_name.ends_with(".tscn") or file_name.ends_with(".tscn.remap"):
				file_names.append(file_name.replace(".remap", ""))
			file_name = dir.get_next()
		
		print("DEBUG: Total valid levels found: ", file_names.size())
		
		if file_names.size() == 0:
			print("CRITICAL: No .tscn files found in ", path, " - Check your folder structure!")

		file_names.shuffle()

		var levels_added = 0
		for f in file_names:
			var full_path = path + f
			
			if "boss" in path:
				if Global.used_bosses.has(full_path):
					print("Skipping boss (already used): ", f)
					continue 
			
			create_card_from_level(full_path)
			levels_added += 1
		
		print("DEBUG: Successfully instantiated ", levels_added, " cards.")

	else:
		print("ERROR: Could not open directory! Does ", path, " exist?")

func create_card_from_level(path: String):
	print("Creating card for: ", path)
	var level_scene = load(path)
	if not level_scene: 
		print("ERROR: Failed to load scene at: ", path)
		return
	
	var temp_node = level_scene.instantiate()
	var new_card = card_scene.instantiate()
	list.add_child(new_card)
	
	# Difficulty color logic
	var diff_raw = temp_node.get("level_difficulty")
	var diff = str(diff_raw).to_lower() if diff_raw else "normal"
	
	var color_easy = Color(0.3, 0.36, 0.94) 
	var color_boss = Color(0.35, 0.02, 0.35) 
	
	var weight := 0.3 # Default
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
