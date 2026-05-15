extends CanvasLayer

@onready var label = $Control/Label

func _ready():
	
	_on_coin_changed(GameStats.coins)
	

	GameStats.coins_changed.connect(_on_coin_changed)

func _on_coin_changed(new_amount):
	label.text = "%04d x" % new_amount
	print("UI updated to: ", new_amount)
