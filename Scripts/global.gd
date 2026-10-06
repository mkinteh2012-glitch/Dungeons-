extends Node
var selected_level_path : String = ""
var levels_completed : int = 0
var levels_until_boss : int = 0
var used_bosses : Array = []
func _ready() -> void:
	NavigationServer2D.set_debug_enabled(false)
	print("Navigation false")
