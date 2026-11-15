extends Node2D

@onready var label: Label = $Label

# controls duration that the damage number is above enemy
@export var duration: float = 0.6

#controls number of pixels the damage number moves upward
@export var pixels: int = 40

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setup(amount: float):
	label.text = str(amount)
	label.add_theme_color_override("font_color", Color.RED)
	
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "position:y", position.y - pixels, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	
	tween.chain().tween_callback(queue_free)
