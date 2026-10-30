extends Area2D
class_name Projectile

@onready var collider: CollisionShape2D = $Collider

var velocity: Vector2 = Vector2.ZERO
var damage: float
var speed: float
var target_group: StringName

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func fire(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	
func _physics_process(delta: float) -> void:
	global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	handle_collision(body)

func _on_area_entered(area: Area2D) -> void:
	handle_collision(area)

func handle_collision(target: Node2D) -> void:
	if not target.is_in_group(target_group):
		return

	var health := target.get_node_or_null("Health") as Health
	if health == null:
		return

	health.take_damage(damage)
	queue_free()
