extends Node

signal coins_changed(new_amount)

# --- CURRENCY & PROGRESS ---
var coins: int = 100 # Starting coins for testing
var current_objective: String = "Exterminate" 
var current_reward_coins: int = 0
var current_difficulty: String = "Normal"

# --- SHOP & BADGE DATA ---
var badge_lookup = {
	"attack": "Attack",
	"defense": "Defense",
	"health": "Health",
	"size": "Size",
	"speed": "Speed",
	"wave": "Wave",
	"cooldown": "Cooldown"
}

# Inside GameStats.gd

var badge_descriptions = {
	"attack": "Increases damage.",
	"defense": "Chance to dodge attacks.",
	"health": "Adds +1 max hearts per level.",
	"size": "Increases dagger size, does not affect arrow",
	"speed": "Move faster per upgrade.",
	"wave": "Bigger, stronger shockwaves.",
	"cooldown": "Reduces arrow launch times, does not affect dagger"
}

# Add a helper function to grab the text safely
func get_badge_description(type: String) -> String:
	var key = type.to_lower()
	return badge_descriptions.get(key, "No description available.")

# The BASE price (Level 1 cost)
var base_prices = {
	"attack": 100,  
	"speed": 100,     
	"health": 250,   
	"defense": 100,   
	"size": 100,      
	"wave": 150,      
	"cooldown": 100   
}
# Current Level (0 = Locked/Unbought)
var ability_levels = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"size": 0,
	"speed": 0,
	"wave": 0,
	"cooldown": 0
}

# The Max Level Cap (Set to -1 for infinite)
var max_levels = {
	"attack": -1,
	"defense": 3,
	"health": 3, 
	"size": 5,
	"speed": -1,
	"wave": 10,
	"cooldown": 10
}

# --- FUNCTIONS ---

func add_coins(amount: int):
	coins += amount
	coins_changed.emit(coins)	

# Calculation: Base Price + (Base Price * current_level)
# Result: Lvl 1 = 200, Lvl 2 = 400, Lvl 3 = 600...
func get_upgrade_cost(type: String) -> int:
	var key = type.to_lower()
	var base = base_prices.get(key, 500)
	var lvl = ability_levels.get(key, 0)
	return base + (base * lvl * 0.5)

func buy_ability(type: String) -> bool:
	var key = type.to_lower()
	var cost = get_upgrade_cost(key)
	var current_lvl = ability_levels.get(key, 0)
	var max_lvl = max_levels.get(key, -1)
	
	# Check if we can afford AND if we aren't at max level
	if coins >= cost:
		if max_lvl == -1 or current_lvl < max_lvl:
			coins -= cost
			ability_levels[key] += 1 # Upgrade the level!
			coins_changed.emit(coins)
			print("Upgraded ", key, " to Level ", ability_levels[key])
			return true
	
	print("Purchase failed for: ", key)
	return false

func get_badge_info(type: String):
	var key = type.to_lower()
	return badge_lookup.get(key, "Unknown")

# --- COMPATIBILITY HELPERS ---
# We use this so your other scripts don't break immediately
var unlocked_abilities:
	get:
		var dict = {}
		for key in ability_levels:
			dict[key] = ability_levels[key] > 0
		return dict
