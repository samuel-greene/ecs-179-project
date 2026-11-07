extends CharacterBody2D
class_name Friendly

@export var move_speed: float = 170.0
@export var tower_clearance: float = 150.0

@onready var attack: MeleeAttack = $MeleeAttack
@onready var health: Health = $Health

var target: Alien
var tower: Node2D


func _ready() -> void:
	add_to_group("friendlies")
	health.died.connect(_on_health_died)

func _on_health_died() -> void:
	queue_free()

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		set_target()

	if not is_instance_valid(tower):
		tower = get_tree().get_first_node_in_group("tower")

	if is_instance_valid(target):
		handle_movement_behavior(delta)

func set_target():
	target = NodeUtils.get_closest_node_in_group(self, "enemies")


func handle_movement_behavior(_delta: float) -> void:
	if attack.is_target_in_range(target):
		velocity = Vector2.ZERO
		attack.execute_attack(target)
		return

	var destination = target.global_position

	if is_instance_valid(tower):
		var to_tower = tower.global_position - global_position
		var to_enemy = target.global_position - global_position

		# Check if the tower is between the friendly and enemy
		var projection = to_tower.normalized().dot(to_enemy.normalized())

		if projection > 0.5:
			# Calculate which side of the tower to move around
			var side = sign(to_tower.cross(to_enemy))

			if side == 0:
				side = 1

			var offset = to_tower.normalized().rotated(side * PI / 2)

			destination = tower.global_position + offset * tower_clearance

	var direction = (destination - global_position).normalized()

	velocity = direction * move_speed
	move_and_slide()
