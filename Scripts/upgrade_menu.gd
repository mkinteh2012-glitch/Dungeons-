extends Control

# Drag your BadgeSlot.tscn file into this slot in the Inspector
@export var badge_card_scene: PackedScene 

@onready var grid = $Panel/GridContainer

func _ready():
	# Initial load
	refresh_shop()
	
	# Connect to GameStats signal to update UI if money changes elsewhere
	if GameStats.has_signal("coins_changed"):
		GameStats.coins_changed.connect(_on_stats_changed)


func _on_stats_changed(_new_amount):
	# Update cards visual state (Locked/Unlocked) when money changes
	for card in grid.get_children():
		if card.has_method("update_appearance"):
			card.update_appearance()

func _on_close_button_pressed():
	# Hide the menu
	self.visible = false

# Call this function from your LevelSelectMenu when the "Shop" button is clicked
func open_menu():
	self.visible = true
	refresh_shop()
	
func refresh_shop():
	# 1. Safety check
	if grid == null:
		print("ERROR: GridContainer not found!")
		return
		
	# 2. Clear the grid
	for child in grid.get_children():
		child.queue_free()
	
	# 3. Get the list of badges from the new levels dictionary
	var badge_keys = GameStats.ability_levels.keys()
	
	for b_id in badge_keys:
		var new_card = badge_card_scene.instantiate()
		grid.add_child(new_card)
		
		# 4. Use the new GameStats functions
		var display_name = GameStats.get_badge_info(b_id)
		var current_price = GameStats.get_upgrade_cost(b_id)
		
		# 5. Initialize the card
		if new_card.has_method("setup"):
			new_card.setup(b_id, display_name, current_price)
