extends Node2D

var radius: float = 0.0

func _ready():
	# This triggers the draw call
	queue_redraw()
	
	# Create the fade-out and self-destruct
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _draw():
	# This draws a circle with a colors array to create a gradient
	# Center is White, Outer edge is Transparent
	var colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	draw_circle_filled_gradient(Vector2.ZERO, radius, colors)

func draw_circle_filled_gradient(pos: Vector2, r: float, colors: PackedColorArray):
	# Helper to draw the radial gradient
	draw_circle(pos, r, colors[0]) # Center
	# Note: For complex gradients, sprites are usually better, 
	# but this draws a solid circle that we fade with the tween.
