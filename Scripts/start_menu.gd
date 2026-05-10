extends Control

@export var first_level_path: String = "res://scenes/levels/level_1.tscn" # Path to your scene
@export var start_tex: Texture2D # Drag your image here

@onready var btn = $CenterContainer/TextureButton

func _ready():
	print("--- MENU DEBUG START ---")
	
	# 1. Force Texture
	if start_tex:
		btn.texture_normal = start_tex
		print("Debug: Texture loaded successfully.")
	else:
		print("Warning: No texture assigned to 'start_tex' in Inspector!")

	# 2. Force Size (So it's not a 0x0 invisible box)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.custom_minimum_size = Vector2(300, 150) # Set this to your image's size
	
	# 3. Connection Check
	if not btn.pressed.is_connected(_on_start_pressed):
		btn.pressed.connect(_on_start_pressed)
		print("Debug: Signal connected via code.")
	
	btn.grab_focus()

func _on_start_pressed():
	print("SUCCESS: Start Button Clicked!")
	
	# Reset Global Data
	if has_node("/root/Global"):
		get_node("/root/Global").reset_all_data()
	
	# Change Scene
	if FileAccess.file_exists(first_level_path):
		get_tree().change_scene_to_file(first_level_path)
	else:
		print("Error: Scene path is wrong: ", first_level_path)
