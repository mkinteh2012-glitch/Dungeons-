extends CanvasLayer # or Control, depending on your setup

@onready var redo_label = $RedoLabel

func _process(_delta):
	# We check GameStats every frame to keep the number accurate
	var lives = GameStats.ability_levels.get("redo", 0)
	
	if lives > 0:
		redo_label.text = "Lives:" + str(lives)
		redo_label.show()
	else:
		redo_label.hide() 
