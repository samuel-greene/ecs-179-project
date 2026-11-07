extends CharacterBody2D
class_name Alien

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
	if not is_instance_valid(target):
		set_target()
	
	if is_instance_valid(target):
		handle_movement_behavior(delta)

func set_target():
	var nearest_target  = NodeUtils.get_closest_node_in_group(self, "friendlies")
	target = nearest_target
	
	if not is_instance_valid(nearest_target ):
		target = nearest_target 
	elif not is_instance_valid(nearest_target ):
		target = nearest_target 
	elif global_position.distance_to(nearest_target .global_position) < global_position.distance_to(nearest_target .global_position):
		target = nearest_target 
	else:
		target = nearest_target 

func handle_movement_behavior(_delta: float) -> void:
	if not attack.is_target_in_range(target):
		var direction: Vector2 = (target.global_position - global_position).normalized()
		
		velocity = direction * move_speed
		
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		attack.execute_attack(target)
