extends Node2D
class_name RangeAttack

## Damage done by a single attack
@export var damage: float = 5.0
## Range at which the attack can be performed
@export var attack_range: float = 300.0
## Cooldown before next attack can be performed
@export var cooldown_time: float = 1.0
## Range attack projectile speed
@export var projectile_speed: float = 1000.0
## Range attack projectile
@export var projectile: PackedScene
## The group to target
@export var target_group: StringName = &"enemies"

var cooldown_remaining: float = 0.0

func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

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

## Thank you ChatGPT
func get_intercept_point(
	launch_position: Vector2,
	target_position: Vector2,
	target_velocity: Vector2
) -> Vector2:
	var offset := target_position - launch_position
	var a := target_velocity.length_squared() - projectile_speed * projectile_speed
	var b := 2.0 * offset.dot(target_velocity)
	var c := offset.length_squared()

	var time := -1.0
	var discriminant := b * b - 4.0 * a * c

	if absf(a) < 0.001:
		if absf(b) > 0.001:
			time = -c / b
	elif discriminant >= 0.0:
		var root := sqrt(discriminant)
		var t1 := (-b - root) / (2.0 * a)
		var t2 := (-b + root) / (2.0 * a)
		if t1 > 0.0:
			time = t1
		if t2 > 0.0 and (time < 0.0 or t2 < time):
			time = t2

	if time < 0.0:
		return target_position # No possible intercept; aim directly.

	return target_position + target_velocity * time

func execute_attack(target: Node2D) -> void:
	if cooldown_remaining > 0.0:
		return
	var aim_point := get_intercept_point(
		global_position,
		target.global_position,
		target.velocity
	)
	var direction := global_position.direction_to(aim_point)

	var new_projectile := projectile.instantiate() as Projectile
	get_tree().current_scene.add_child(new_projectile)
	new_projectile.global_position = global_position
	new_projectile.speed = projectile_speed
	new_projectile.damage = damage
	new_projectile.target_group = target_group
	new_projectile.fire(direction)
	cooldown_remaining = cooldown_time
