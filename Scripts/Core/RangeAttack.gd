extends Attack
class_name RangeAttack

@export var projectile_speed: float = 1000.0
@export var projectile: PackedScene
@export var target_group: StringName = &"enemies"


func _init() -> void:
	attack_range = 300.0


func _perform_attack(target: Node2D) -> bool:
	if projectile == null:
		push_warning("RangeAttack has no projectile scene.")
		return false

	var new_projectile := projectile.instantiate() as Projectile
	if new_projectile == null:
		push_warning("Projectile scene must have a Projectile root.")
		return false

	var target_velocity: Vector2 = target.velocity
	var aim_point := get_intercept_point(
		global_position,
		target.global_position,
		target_velocity
	)

	get_tree().current_scene.add_child(new_projectile)
	new_projectile.global_position = global_position
	new_projectile.speed = projectile_speed
	new_projectile.damage = damage
	new_projectile.target_group = target_group
	new_projectile.fire(global_position.direction_to(aim_point))
	return true


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
