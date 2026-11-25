extends Area2D
class_name CoinDrop
## A dropped coin pops up, hovers while spinning and bobbing, then drops,
## bounces once, and settles face-forward on the ground.
## Attach to the root node of Coin.tscn (needs a child Sprite2D named "Sprite2D").

# each coin is worth 5 currency
@export var coin_value = 5



@export_group("Hover")
## How high the coin floats above the ground (px).
@export var hover_height: float = 26.0
## Seconds spent hovering (spinning and bobbing) before it drops.
@export var hover_time: float = 0.4
@export var rise_time: float = 0.18
@export var bob_height: float = 3.0
@export var bob_speed: float = 10.0
## Spin speed in radians per second (about 6.3 = one turn per second).
@export var spin_speed: float = 10.0
## How far from the death spot the coin can drift (px).
@export var scatter_distance: float = 40.0

@export_group("Drop")
@export var drop_time: float = 0.18
@export var bounce_height: float = 8.0
@export var bounce_time: float = 0.07
## Seconds for the spin to wind down so the coin lands face-forward.
@export var settle_time: float = 0.25

@export_group("Shadow")
@export var shadow_radius: float = 12.0
@export var shadow_alpha: float = 0.3
@export var shadow_offset_y: float = 20.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CoinShape

var _base_scale: Vector2
var _base_position: Vector2
var _height: float = 0.0  # how far above the ground the coin is (px)
var _bob_amount: float = 1.0
var _landed: bool = false
var _time: float = 0.0
var _spin_angle: float = 0.0
var _collision_base_position: Vector2
var _collected: bool = false


func _ready() -> void:
	_base_scale = _sprite.scale
	_base_position = _sprite.position
	_time = randf() * TAU  # so several coins don't bob in sync
	# The enemy sets this coin's position right AFTER adding it to the scene,
	# so wait until the end of the frame before reading it.
	_start_sequence.call_deferred()
	_collision_base_position = _collision.position


func _start_sequence() -> void:
	# Drift to a random spot near where the enemy died.
	var landing := position + Vector2.from_angle(randf() * TAU) \
		* randf_range(scatter_distance * 0.4, scatter_distance)
	create_tween().tween_property(self, "position", landing, rise_time + 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var seq := create_tween()
	# 1. Pop up into the air.
	seq.tween_property(self, "_height", hover_height, rise_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 2. Hover. The spin and bob are handled in _process.
	seq.tween_interval(hover_time)
	# 3. Drop, fading the bob out as it falls.
	seq.tween_property(self, "_height", 0.0, drop_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	seq.parallel().tween_property(self, "_bob_amount", 0.0, drop_time * 0.5)
	# 4. One small bounce.
	seq.tween_property(self, "_height", bounce_height, bounce_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	seq.tween_property(self, "_height", 0.0, bounce_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	seq.tween_callback(_on_landed)


func _on_landed() -> void:
	_landed = true
	UISounds.play("coin", 0.05)
	queue_redraw()
	# Wind the spin down so the coin ends up facing forward.
	var face_forward := (floorf(_spin_angle / TAU) + 2.0) * TAU
	create_tween().tween_property(self, "_spin_angle", face_forward, settle_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	if not _landed:
		_spin_angle += spin_speed * delta
		queue_redraw()  # the shadow changes while the coin is in the air

	_sprite.scale = Vector2(_base_scale.x * cos(_spin_angle), _base_scale.y)
	var bob := sin(_time * bob_speed) * bob_height * _bob_amount
	_sprite.position = _base_position + Vector2(0.0, -_height - bob)
	_collision.position = _collision_base_position + Vector2(0.0, -_height - bob)



# Ground shadow: shrinks and fades as the coin rises.
func _draw() -> void:
	var lift := clampf(_height / hover_height, 0.0, 1.0)
	draw_set_transform(Vector2(0.0, shadow_offset_y), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, shadow_radius * (1.0 - 0.4 * lift),
		Color(0.0, 0.0, 0.0, shadow_alpha * (1.0 - 0.6 * lift)))
		
		
		
# Collect the coin when the mouse hovers over it (once it has landed).
func _physics_process(_delta: float) -> void:
	if _landed and not _collected and _is_mouse_over():
		GameData.currency += coin_value
		collect_coin()


func _is_mouse_over() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	for result in get_world_2d().direct_space_state.intersect_point(query):
		if result["collider"] == self:
			return true
	return false


func collect_coin() -> void:
	if _collected:
		return

	_collected = true
	UISounds.play("coin_pickup", 0.08)
	Effects.popup_text(global_position + Vector2(0.0, -24.0), "+" + str(coin_value), Color(1.0, 0.79, 0.2))
	Effects.burst(global_position, Color(1.0, 0.79, 0.2), 6, 70.0)
	set_physics_process(false)
	_collision.set_deferred("disabled", true)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(_sprite, "modulate:a", 0.2, 0.2)
	tween.tween_property(self, "position:y", position.y - 15.0, 0.2)

	tween.chain().tween_callback(queue_free)
