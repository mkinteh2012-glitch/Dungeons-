extends CharacterBody2D

@export var speed := 150  # pixels per second

func _physics_process(delta):
	var input_vector := Vector2.ZERO

	# Input
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1

	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized() * speed

	# Set velocity
	velocity = input_vector

	# Move and collide
	move_and_slide()

	# Handle animation and facing
	var sprite = $AnimatedSprite2D

	# Switch Idle/Run
	if velocity.length() > 0:
		if sprite.animation != "Run":
			sprite.animation = "Run"
			sprite.play()
	else:
		if sprite.animation != "Idle":
			sprite.animation = "Idle"
			sprite.play()

	# Flip sprite for left/right facing
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0  # facing left if moving left
