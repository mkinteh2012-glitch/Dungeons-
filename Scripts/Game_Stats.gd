extends Node

signal coins_changed(new_amount)

var coins: int = 0
var current_objective: String = "Exterminate" 
var current_reward_coins: int = 0
var current_difficulty: String = "Normal"

func add_coins(amount: int):
	coins += amount
	print("Coins in terminal: ", coins)
	coins_changed.emit(coins)	

# 1. Lookup for your Animations
var badge_lookup = {
	"attack": "Attack",
	"defense": "Defense",
	"health": "Health",
	"size": "Size",
	"speed": "Speed",
	"wave": "Wave",
	"cooldown": "Cooldown" # Matches the name in your animation list
}

# 2. Ability States
# Set to 'false' so they show up in your "selection" pool
var unlocked_abilities = {
	"attack": false, #done
	"defense": false,#done
	"health": false,#done
	"size": false,#done
	"speed": false,#done
	"wave": false,#done
	"cooldown": false#done
}

# Fetch the Animation name for the UI
func get_badge_info(type: String):
	var key = type.to_lower()
	if badge_lookup.has(key):
		return badge_lookup[key]
	return "Health"

func unlock_ability(type: String):
	var key = type.to_lower()
	if unlocked_abilities.has(key):
		unlocked_abilities[key] = true
		print("Ability unlocked in GameStats: ", key)
	
func get_random_locked_ability() -> String:
	var locked_list = []
	
	for ability in unlocked_abilities:
		if unlocked_abilities[ability] == false:
			locked_list.append(ability)
	
	if locked_list.size() == 0:
		return "health" # Fallback if everything is unlocked
	
	return locked_list.pick_random()
