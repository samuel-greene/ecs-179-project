extends CharacterBody2D
class_name Enemy3

@export var move_speed: float = 150.0
@export var coin_scene: PackedScene

@onready var attack: MeleeAttack = $MeleeAttack
@onready var health: Health = $Health

var target: Node2D

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_health_died)

func _on_health_died() -> void:
	var coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position
	
	queue_free()

func _physics_process(delta: float) -> void:
	# 1. If no target is found, find one
	if not is_instance_valid(target):
		set_target()
	
	# 2. If a valid target exists, move toward it
	if is_instance_valid(target):
		handle_movement_behavior(delta)

func set_target():
	var nearest_target = NodeUtils.get_closest_node_in_group(self, "friendlies")
	target = nearest_target

func handle_movement_behavior(_delta: float) -> void:
	if not attack.is_target_in_range(target):
		# Calculate direction
		var direction: Vector2 = (target.global_position - global_position).normalized()
		
		velocity = direction * move_speed
		
		move_and_slide()
	else:
		# Stop moving when in range
		velocity = Vector2.ZERO
		attack.execute_attack(target)
