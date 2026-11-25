extends HBoxContainer

@onready var _label: Label = $Count

var _shown: int = -1


func _process(_delta: float) -> void:
	if GameData.currency == _shown:
		return

	# small pop when coins are collected
	if _shown != -1:
		pivot_offset = size / 2.0
		scale = Vector2(1.2, 1.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.15)

	_shown = GameData.currency
	_label.text = str(_shown)
