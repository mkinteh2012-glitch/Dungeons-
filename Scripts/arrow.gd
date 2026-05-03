extends Area2D
@onready var player = get_tree().get_first_node_in_group("player")
# Using a Setter: This runs the second 'arrow_size' is changed by the player
var arrow_size: Vector2 = Vector2(1, 1):
	set(value):
		arrow_size = value
		self.scale = value # Force the Area2D to resize immediately
		print("Arrow scale confirmed at: ", value)

var direction = Vector2.ZERO
var speed = 0.0
var damage = 10.0
var max_lifetime = 7.0
var is_launched := false
var is_max_power := false 

func _ready():
	add_to_group("projectile")
	# Final check to apply scale when entering the scene
	self.scale = arrow_size

func _physics_process(delta):
	if is_launched:
		global_position += direction * speed * delta
		rotation = direction.angle() + PI/2

func launch():
	is_launched = true
	if max_lifetime > 0:
		get_tree().create_timer(max_lifetime).timeout.connect(queue_free)

func _on_body_entered(body):
	_handle_hit(body)

func _on_area_entered(area):	
	_handle_hit(area)

func _handle_hit(victim):
	if not is_launched: return
	if victim.is_in_group("player"): return

	var current_node = victim
	var health_node = null
	
	for i in range(3):
		if current_node == null: break
		health_node = current_node.get_node_or_null("Health")
		if health_node: break
		current_node = current_node.get_parent()

	if health_node and health_node.has_method("take_damage"):
		health_node.take_damage(damage)
		if is_max_power:
			player.spawn_wave()
			_trigger_impact_juice()
		queue_free()
		
	elif victim.has_method("take_damage"):
		victim.take_damage(damage)
		if is_max_power:
			player.spawn_wave()
			_trigger_impact_juice()
		queue_free()
		
	elif victim.is_in_group("walls") or victim is TileMap or victim is TileMapLayer:
		queue_free()

func _trigger_impact_juice():
	if has_node("GPUParticles2D"):
		var particles = $GPUParticles2D
		var pos = particles.global_position
		
		# Reparent particles so they survive the arrow's queue_free()
		remove_child(particles)
		get_tree().current_scene.add_child(particles)
		
		particles.global_position = pos
		particles.emitting = true
		get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("hit_pause"):
		player.hit_pause(0.06)
