extends StaticBody2D
class_name Tower

@onready var health: Health = $Health
@onready var attack: Attack = $Attack

var target: Enemy

func _ready() -> void:
	add_to_group("friendlies")
	health.died.connect(_on_health_died)

func _on_health_died() -> void:
	queue_free()

func _process(_delta: float) -> void:
	# 1. If no target is found, find one
	if not is_instance_valid(target):
		set_target()
	
	# 2. If a valid target exists, move toward it
	if is_instance_valid(target):
		handle_attack_behavior()

func set_target():
	var nearest_target = NodeUtils.get_closest_node_in_group(self, "enemies")
	target = nearest_target
	
func handle_attack_behavior():
	if attack.is_target_in_range(target):
		attack.execute_attack(target)
