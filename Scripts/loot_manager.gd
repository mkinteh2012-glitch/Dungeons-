extends Node

var heart_scene = preload("res://Sprites/Heart.tscn")
var BADGE_SCENE = preload("res://Sprites/badge.tscn")
func _ready():
	
	print("!!! LOOT MANAGER IS ALIVE !!!")
	get_tree().node_removed.connect(_on_node_removed)

func _on_node_removed(node):
	
	if node.is_in_group("enemy"):
		print("An ENEMY died! Spawning loot at: ", node.global_position)
		spawn_loot(node.global_position)
		if node.has_meta("Boss"): 
			print("BOSS")
			spawn_boss_badge(node.global_position)


var coin_scene = preload("res://sprites/Coin.tscn")

func spawn_loot(pos: Vector2):
	# --- 1. HEART ROLL (Independent) ---
	# 1 in 8 chance. This happens regardless of the coin roll.
	if randi() % 10 == 0:
		print("JACKPOT: Dropped a Heart!")
		_create_item(heart_scene, pos)

	# --- 2. COIN ROLL (Cascading) ---
	# Guaranteed 1st coin, then 80%, 60%, 40%, 20%
	var coin_chance = 0.9
	var reduction = 0.2
	
	while randf() < coin_chance:
		_create_item(coin_scene, pos)
		coin_chance -= reduction
		
		if coin_chance <= 0:
			break

# Helper function to handle the actual spawning and physics "pop"
func _create_item(scene: PackedScene, pos: Vector2):
	if not scene: 
		return
		
	var item = scene.instantiate()
	item.global_position = pos
	
	# Add to the main game scene so it doesn't die with the enemy
	get_tree().current_scene.add_child.call_deferred(item)


	
	# THE "POP" EFFECT
	# Pick a random direction and distance
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var travel_dist = randf_range(5, 10)
	var target_pos = item.global_position + (random_dir * travel_dist)
	
	# Animate the item 'flying' out from the center
	var tween = create_tween()
	# This makes it move out and slightly slow down (Ease Out)
	tween.tween_property(item, "global_position", target_pos, 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func spawn_boss_badge(pos: Vector2):
	var instance = BADGE_SCENE.instantiate()
	
	# Logic stays in GameStats! 
	# We ask GameStats for the "Speed" animation name
	var type = GameStats.get_random_locked_ability()
	var anim_name = GameStats.get_badge_info(type)

	instance.global_position = pos
	instance.badge_type = anim_name 
	
	get_tree().current_scene.add_child(instance)
