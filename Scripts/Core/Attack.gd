extends Node2D
class_name Attack

## Damage done by a single attack
@export var damage: float = 5.0
## Range at which the attack can be performed
@export var attack_range: float = 30.0
## Cooldown before next attack can be performed.
## Every Attack scene owns a child Timer named "Cooldown".
@onready var cooldown: Timer = $Cooldown

## Returns true when any point on the target's collision shape is in attack range.
func is_target_in_range(target: Node2D) -> bool:
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return global_position.distance_to(target.global_position) <= attack_range

	var point_in_shape_space := collision_shape.to_local(global_position)
	var closest_point := _get_closest_point_on_shape(point_in_shape_space, collision_shape.shape)
	var point_in_world_space := collision_shape.to_global(closest_point)
	return global_position.distance_to(point_in_world_space) <= attack_range

func _get_closest_point_on_shape(point: Vector2, shape: Shape2D) -> Vector2:
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		if point.length() <= circle.radius:
			return point
		return point.normalized() * circle.radius

	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		var half_size := rectangle.size * 0.5
		return Vector2(
			clampf(point.x, -half_size.x, half_size.x),
			clampf(point.y, -half_size.y, half_size.y)
		)

	# Targets without a supported shape use their origin as a safe fallback.
	return Vector2.ZERO

func execute_attack(target: Node2D) -> void:
	var target_health_component = target.get_node_or_null("Health")
	
	if not cooldown.is_stopped():
		return
	if target_health_component:
		var health = target_health_component as Health
		health.take_damage(damage);
		cooldown.start()
		#print("Attacking: " + target.name)
	else:
		push_warning("Target " + target.name + " has no valid Health component")
