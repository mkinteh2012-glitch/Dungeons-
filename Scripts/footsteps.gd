extends AudioStreamPlayer2D

# 1. Define the presets for different enemy types
var footstep_presets = {
	"default": {"pitch": 1.0, "volume": 0.0, "variation": 0.2, "threshold": 5.0},
	"peon":    {"pitch": 0.8, "volume": 0.0, "variation": 0.1, "threshold": 5.0},
	"skitter": {"pitch": 1.5, "volume": -10.0, "variation": 0.4, "threshold": 10.0},
	"boomkin": {"pitch": 1.5, "volume": -10.0, "variation": 0.4, "threshold": 10.0},
	"vex":     {"pitch": 0.6, "volume": -15.0, "variation": 0.05, "threshold": 2.0},
}

## Type the name of the enemy here (peon, skitter, vex, etc.)
@export var enemy_type: String = "default"

@onready var parent = get_parent()

func _ready() -> void:
	# Apply the initial volume from the dictionary
	if footstep_presets.has(enemy_type.to_lower()):
		var data = footstep_presets[enemy_type.to_lower()]
		volume_db = data["volume"]
	else:
		print("Warning: enemy_type '", enemy_type, "' not found in dictionary. Using default.")

func _physics_process(_delta: float) -> void:
	# 1. ADDED: Ensure the parent and the dictionary are actually there
	if not parent or not is_instance_valid(parent):
		return
		
	if not "velocity" in parent:
		return
	
	# 2. Get the preset (with a fallback to avoid the 'Nil' error)
	var type_key = enemy_type.to_lower()
	if footstep_presets == null or not footstep_presets.has(type_key):
		type_key = "default"
		
	var stats = footstep_presets[type_key]
	
	# 3. Movement Logic
	if parent.velocity.length() > stats["threshold"]:
		if not playing:
			# Randomize pitch based on the dictionary values
			var base_pitch = stats["pitch"]
			var var_range = stats["variation"]
			pitch_scale = randf_range(base_pitch - var_range, base_pitch + var_range)
			play()
	else:
		if playing:
			stop()
