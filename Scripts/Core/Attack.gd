extends Node2D
class_name Attack

@export var damage: float = 5.0
@export var attack_range: float = 30.0
@export var cooldown_time: float = 1.0

var cooldown_remaining: float = 0.0


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func is_target_in_range(target: Node2D) -> bool:
	var collision_shape := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return global_position.distance_to(target.global_position) <= attack_range

	var local_point := collision_shape.to_local(global_position)
	var closest_point := _get_closest_point_on_shape(local_point, collision_shape.shape)
	var world_point := collision_shape.to_global(closest_point)
	return global_position.distance_to(world_point) <= attack_range


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

	return Vector2.ZERO


func execute_attack(target: Node2D) -> void:
	if cooldown_remaining > 0.0 or not is_instance_valid(target):
		return

	if not is_target_in_range(target):
		return

	if _perform_attack(target):
		cooldown_remaining = cooldown_time


## Override in subclasses. Return true when the attack succeeds.
func _perform_attack(_target: Node2D) -> bool:
	push_error("Attack subclasses must implement _perform_attack().")
	return false
