extends TextureButton

var target_level_path: String 

func _ready():
	# 1. Automatic Signal Connection (Just in case you forgot in the editor)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	
	# 2. Visual Debugging
	print("--- CARD DEBUG: ", name, " ---")
	print("Position: ", position)
	print("Size: ", size)
	print("Visible: ", visible)
	print("Modulate Alpha: ", modulate.a)
	
	if size.x == 0 or size.y == 0:
		print("WARNING: Card size is 0! It will be invisible. Set 'Custom Minimum Size' in Inspector.")

func setup(data: Dictionary):
	# Using get_node_or_null to prevent crashes if nodes are missing
	var name_label = get_node_or_null("Levelname")
	var reward_label = get_node_or_null("Reward")
	var diff_label = get_node_or_null("Difflabel")
	
	if name_label: name_label.text = data["name"]
	if reward_label: reward_label.text = str(data["reward"]) + "x"
	if diff_label: diff_label.text = data["difficulty"]
	
	target_level_path = data["path"] 
	print("Card setup complete for: ", data["name"], " -> ", target_level_path)

func _on_pressed():
	print("BUTTON CLICKED: ", target_level_path)
	
	if target_level_path != "":
		if "boss" in target_level_path:
			Global.used_bosses.append(target_level_path)
			print("Boss added to history.")
		
		Global.selected_level_path = target_level_path
		GameStats.refresh_lives_for_new_level()
		print("Global path set. Changing scene...")
		
		# Use call_deferred for scene changes to prevent the 'Parent Busy' error
		get_tree().call_deferred("change_scene_to_file", "res://game.tscn")
	else:
		print("ERROR: This card has no level path assigned!")
		
