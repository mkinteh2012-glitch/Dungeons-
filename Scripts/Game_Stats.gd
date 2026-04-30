extends Node

signal coins_changed(new_amount) # 1. Make sure this exists at the top

var coins: int = 0

func add_coins(amount: int):
	coins += amount
	print("Coins in terminal: ", coins) # This is working for you!
	coins_changed.emit(coins)	
var badge_lookup = {
	"speed": "Speed",
	"health": "Health",
	"attack": "Attack"
}

var unlocked_abilities = {
	"speed": false,
	"health": false,
	"attack": true
}

# This is the function the LootManager or Boss calls
func get_badge_info(type: String):
	if badge_lookup.has(type):
		return badge_lookup[type] # Returns the animation name (e.g. "Speed")
	return "Health" # Default fallback

func unlock_ability(type: String):
	unlocked_abilities[type.to_lower()] = true
	print("Ability unlocked in GameStats: ", type)
	
func get_random_locked_ability() -> String:
	var locked_list = []
	
	# Find everything the player DOESN'T have yet
	for ability in unlocked_abilities:
		if unlocked_abilities[ability] == false:
			locked_list.append(ability)
	
	# If the player has everything, just default to "health" or a coin bonus
	if locked_list.size() == 0:
		return "health"
	
	# Pick a random one from the locked list
	return locked_list.pick_random() 
