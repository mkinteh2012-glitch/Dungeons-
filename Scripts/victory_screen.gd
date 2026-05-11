extends Control

# Use @onready to grab the nodes from your tree
@onready var badge_container = $Panel/Badge_Label
@onready var coin_lbl = $Panel/Coin_Label
var coins = GameStats.coins
var my_font = preload("res://Fonts/PressStart2P-Regular.ttf")
func _ready():
	display_stats()
	create_background_drift()	

func display_stats():
	# 1. Update Coin Label (Assuming Coin_Label is a separate Label node)
	$Panel/Coin_Label.text = "Total Coins:" + str(GameStats.coins)
	if coins == 0:
		coin_lbl.modulate = Color.DARK_GRAY # Broke
	elif coins < 100:
		coin_lbl.modulate = Color.WHITE     # Getting started
	elif coins < 550:
		coin_lbl.modulate = Color.GREEN_YELLOW # Doing well
	else:
		coin_lbl.modulate = Color.GOLD      # Loaded!
		var tween = create_tween().set_loops()
		tween.tween_property(coin_lbl, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(coin_lbl, "scale", Vector2(1.0, 1.0), 0.5)
		# Ensure pivot is centered so it scales from the middle
		coin_lbl.pivot_offset = coin_lbl.size / 2
	
	# Add an outline so it's readable against the background
	coin_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	coin_lbl.add_theme_constant_override("outline_size", 6)
	# 2. Clear previous entries
	for child in badge_container.get_children():
		child.queue_free()

	# 4. Add items
	var has_upgrades = false
	for ability in GameStats.ability_levels.keys():
		var level = GameStats.ability_levels[ability]
		if level > -1:
			var display_name = GameStats.get_badge_info(ability)
			var lbl = Label.new()
			lbl.text = display_name + ": Lv." + str(level)
			lbl.add_theme_font_override("font", my_font)
			lbl.add_theme_font_size_override("font_size", 16) 
			# --- DYNAMIC COLOR LOGIC ---
			if level == 0:
				# Dimmed/Gray for unowned stats
				lbl.modulate = Color(0.4, 0.4, 0.4, 1.0) 
			elif level >= 1 and level <= 2:
				# Standard White for early levels
				lbl.modulate = Color.WHITE
			elif level >= 3 and level <= 4:
				# Light Blue/Cyan for intermediate
				lbl.modulate = Color.AQUAMARINE
			elif level >= 5:
				# Golden/Yellow for high levels or Max
				lbl.modulate = Color.YELLOW
				var tween = create_tween().set_loops()
				tween.tween_property(lbl, "modulate:a", 0.5, 0.8)
				tween.tween_property(lbl, "modulate:a", 1.0, 0.8)
		# ---------------------------
			# Ensure the labels don't try to overlap
			lbl.custom_minimum_size.y = 10 
			
			# Add this inside your loop
			lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			lbl.add_theme_constant_override("outline_size", 4)
			badge_container.add_child(lbl)
			has_upgrades = true
			
	if not has_upgrades:
		var none_lbl = Label.new()
		none_lbl.text = "No upgrades this run."
		badge_container.add_child(none_lbl)
		
func create_background_drift():
	for i in range(45): # Create 15 floating pixels
		var pixel = ColorRect.new()
		pixel.size = Vector2(3, 3) # Tiny 2x2 pixel
		pixel.color = Color(1, 1, 1, 0.6) # Semi-transparent white
		pixel.position = Vector2(randf() * 1152, randf() * 648) # Random spot
		
		# Put it BEHIND the Panel
		add_child(pixel)
		move_child(pixel, 0) 
		
		# Make it drift upwards forever
		var tween = create_tween().set_loops()
		var target_pos = pixel.position + Vector2(0, -600)
		tween.tween_property(pixel, "position", target_pos, randf_range(5.0, 10.0))
		tween.set_trans(Tween.TRANS_LINEAR)
		
func _on_restart_button_pressed():
	get_tree().change_scene_to_file("res://UI/StartMenu.tscn")
	print("Pressed")
