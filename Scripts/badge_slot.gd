extends TextureButton

var badge_id: String
var cost: int

@onready var anim_sprite = $Badge/AnimatedSprite2D 
@onready var price_label = $PriceLabel

func setup(id: String, d_name: String, price_value: int, _tex = null):
	badge_id = id 
	cost = price_value
	
	if not is_node_ready():
		await ready
	
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation(d_name):
			anim_sprite.play(d_name)
		else:
			print("Warning: AnimatedSprite2D missing animation: ", d_name)
	
	update_appearance()

func update_appearance():

	var current_lvl = GameStats.ability_levels.get(badge_id, 0)
	var max_lvl = GameStats.max_levels.get(badge_id, -1)
	

	if has_node("DescriptionLabel"):
		$DescriptionLabel.text = GameStats.get_badge_description(badge_id)

		$DescriptionLabel.visible = false 
	
	if current_lvl > 0:
		self.modulate = Color.WHITE
		if max_lvl != -1 and current_lvl >= max_lvl:
			$PriceLabel.text = "MAX"
		else:
			$PriceLabel.text = str(GameStats.get_upgrade_cost(badge_id))
		
		$BuyButton.text = "Lvl " + str(current_lvl)
	else:
		$PriceLabel.text = str(GameStats.get_upgrade_cost(badge_id))
		$BuyButton.text = "Buy"
		self.modulate = Color(0.6, 0.6, 0.6, 1.0)

func _on_pressed():
	if GameStats.buy_ability(badge_id):
		update_appearance()
		#refresh the coin cointer
		if get_parent().has_method("refresh_shop"):
			get_parent().refresh_shop()

func _on_mouse_entered():
	if has_node("DescriptionLabel"):
		$DescriptionLabel.visible = true

func _on_mouse_exited():
	if has_node("DescriptionLabel"):
		$DescriptionLabel.visible = false
