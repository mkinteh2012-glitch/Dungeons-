extends Control

# Match these names exactly to your scene tree
@onready var start_button = $TextureButton
@onready var title_label = $Label
@onready var sub_label = $Label2 # The 'Start' text label
@onready var music_player = $AudioStreamPlayer

func _ready():
	# 1. Reset Game Progress
	# This ensures the player starts with fresh lives/stats
	GameStats.level_in_progress = false
	
	# 2. Play the Title Music
	if music_player.stream:
		music_player.play()
	
	# 3. Setup Button Signal
	# You can also do this in the 'Node' tab, but code is safer!
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	print("Starting Game...")
	get_tree().change_scene_to_file("res://UI/LevelSelectMenu.tscn")
	GameStats.coins = 0
	Global.levels_completed = 0
	Global.selected_level_path = ""
	Global.levels_completed = 0
	Global.used_bosses = []
	GameStats.coins = 50
	GameStats.current_floor = 1
	GameStats.ability_levels = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"size": 0,
	"speed": 0,
	"wave": 0,
	"redo": 0,
	"cooldown": 0
}
	GameStats.level_in_progress = false
# Optional: Add some juice!
func _process(_delta):
	# Make the title 'Dungeons' bob up and down slowly
	var time = Time.get_ticks_msec() * 0.002
	title_label.position.y = 22 + (sin(time) * 5)


func _on_texture_button_pressed() -> void:
	pass # Replace with function body.
