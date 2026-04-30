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
	"health": true,
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
