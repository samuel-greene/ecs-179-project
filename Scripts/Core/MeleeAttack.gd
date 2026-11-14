extends Attack
class_name MeleeAttack


func _perform_attack(target: Node2D) -> bool:
	var health := target.get_node_or_null("Health") as Health
	if health == null:
		push_warning("Target " + target.name + " has no valid Health component")
		return false

	health.take_damage(damage)
	return true
