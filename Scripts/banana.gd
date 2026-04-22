extends Area2D

@export var speed := 200.0
@export var return_delay := 2	
@export var max_lifetime := 7.6 # New variable for self-destruction
@export var damage := 1

var direction := Vector2.ZERO
var player = null
var is_returning := false
var life_timer := 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	life_timer += delta
	
	if life_timer >= max_lifetime:
		queue_free()
		return # Stop processing the rest of the code for this frame
	
	# 2. RETURN LOGIC
	if not is_returning and life_timer >= return_delay:
		is_returning = true
	
	if is_returning and player:
		var dir_to_player = global_position.direction_to(player.global_position)
		direction = lerp(direction, dir_to_player, 0.04)
		speed = lerp(speed, 350.0, 0.02)
	
	global_position += direction * speed * delta
	rotation_degrees += 20 

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	
