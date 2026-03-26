extends CanvasLayer

@onready var heart_sprite = $AnimatedSprite2D

func _ready():

	var player = get_tree().get_first_node_in_group("player")
	
	if player:
	
		var health_node = player.get_node("Health")
		
		if health_node:
		
			health_node.health_changed.connect(update_hearts)
			
			
			update_hearts(health_node.current_health)
		else:
			print("HUD Error: Player found, but it has no 'Health' node!")
	else:
		print("HUD Error: No node in 'player' group found!")

func update_hearts(current_health: int):

	var frame_index = clamp(6 - current_health, 0, 6)
	heart_sprite.frame = frame_index
