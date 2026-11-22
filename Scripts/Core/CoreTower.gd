extends Tower


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	health.died.connect(core_tower_death)

func core_tower_death() -> void:
	UISounds.play("core_destroyed")
	get_tree().call_deferred("change_scene_to_file", "res://Scenes/Shop.tscn")
