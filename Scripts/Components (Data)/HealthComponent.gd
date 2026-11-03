extends Node
class_name Health

@export var max_health: float = 20
@export var starting_health: float = 20
@export var health_bar: ProgressBar

signal healed(amount: float)
signal received_damage(amount: float)
signal died

var current_health: float = 20

func _ready() -> void:
	current_health = starting_health
	update_health_bar()
	

func take_damage(amount: float):
	if current_health <= 0:
		return
	
	var damage_taken = 0
	if current_health - amount > 0:
		current_health -= amount
		update_health_bar()
		damage_taken = amount
		print(get_parent().name + ": " + str(current_health))
	else:
		damage_taken = current_health
		current_health = 0
		
		if health_bar != null:
				health_bar.visible = false
	
	received_damage.emit(damage_taken)
	
	if current_health == 0:
		died.emit()
		print(get_parent().name + " died")

func gain_health(amount: float):
	var health_gained = 0
	if current_health + amount < max_health:
		update_health_bar()
		current_health += amount
		health_gained = amount
	else:
		health_gained = max_health - current_health
		update_health_bar()
		
	healed.emit(health_gained)

#Updates the health bar of a character if they have one assigned through the 
#inspector	
func update_health_bar():
	#if character has a health bar assigned, update it
	if health_bar == null:
		return
	else:
		health_bar.max_value = max_health
		health_bar.value = current_health
		
