extends CharacterBody2D
class_name Alien

@export var move_speed: float = 150.0
@export var coin_scene: PackedScene
@export var attack: Attack
@export var attack_wait_time: float = 0.25

@onready var health: Health = $Health

# tracks the cooldown in between mouse clicks
var mouse_cooldown: float = 0.0

var target: Node2D

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var first_alien = get_tree().get_first_node_in_group("enemies")
			
			if first_alien != self:
				return
				
			mouse_attack()

func _ready() -> void:
	add_to_group("enemies")
	health.died.connect(_on_health_died)

func _on_health_died() -> void:
	var coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)
	coin.global_position = global_position
	
	queue_free()

func _physics_process(delta: float) -> void:
	mouse_cooldown = maxf(0.0, mouse_cooldown - delta)
	
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

# this function implements the attack on the aliens from the players mouse
func mouse_attack():
	if mouse_cooldown > 0.0:
			return
		
	mouse_cooldown = attack_wait_time
	
	var space_state = get_world_2d().direct_space_state
	
	var mouse = PhysicsPointQueryParameters2D.new()
	mouse.position = get_global_mouse_position()
	mouse.collide_with_areas = true
	mouse.collide_with_bodies = true
	
	var aliens_collided = space_state.intersect_point(mouse)
	
	for a in aliens_collided:
		var alien = a["collider"]
		
		if alien.is_in_group("enemies"):
			alien.health.take_damage(3)
