extends CanvasLayer

@onready var label = $Control/Label

func _ready():
	# Make sure this function name matches Line 7 exactly
	_on_coin_changed(GameStats.coins)
	
	# Check Game_Stats.gd: if the signal has an 's', add it here too!
	GameStats.coins_changed.connect(_on_coin_changed)

func _on_coin_changed(new_amount):
	label.text = "%04d x" % new_amount
	print("UI updated to: ", new_amount)
