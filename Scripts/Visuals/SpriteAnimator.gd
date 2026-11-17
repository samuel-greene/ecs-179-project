extends Sprite2D
class_name SpriteAnimator

@export var flip_with_movement: bool = true
## Movement faster than this counts as walking
@export var walk_threshold: float = 15.0

@export_group("Idle")
@export var idle_bob_height: float = 1.5
@export var idle_bob_speed: float = 2.5

@export_group("Walk")
@export var walk_bob_height: float = 1.8
@export var walk_bob_speed: float = 9.0
@export var walk_tilt_degrees: float = 3.0
@export var walk_squash: float = 0.03

@export_group("Attack")
@export var windup_distance: float = 4.0
@export var windup_time: float = 0.06
@export var lunge_distance: float = 10.0
@export var lunge_time: float = 0.07
@export var recover_time: float = 0.15

@export_group("Projectile Jolt")
@export var jolt_scale: Vector2 = Vector2(1.18, 0.86)
@export var jolt_rotation_degrees: float = 9.0
@export var jolt_rebound_time: float = 0.06
@export var jolt_recover_time: float = 0.14

var _body: Node2D
var _base_position: Vector2
var _base_scale: Vector2
var _base_rotation: float
var _last_position: Vector2
var _speed: float = 0.0
var _walk_blend: float = 0.0
var _time: float = 0.0
var _attack_offset: Vector2 = Vector2.ZERO
var _attack_tween: Tween
var _attack_scale: Vector2 = Vector2.ONE
var _attack_rotation: float = 0.0


func _ready() -> void:
	_body = get_parent() as Node2D
	if _body == null:
		push_warning("SpriteAnimator needs a Node2D parent")
		set_process(false)
		set_physics_process(false)
		return

	_base_position = position
	_base_scale = scale
	_base_rotation = rotation
	_last_position = _body.global_position
	_time = randf() * TAU  #so that units in a group don't bob in lockstep

	for child in _body.get_children():
		if child is Attack:
			child.attacked.connect(_on_attacked.bind(child))

func _physics_process(delta: float) -> void:
	var moved := _body.global_position - _last_position
	_last_position = _body.global_position
	_speed = lerpf(_speed, moved.length() / delta, 0.3)

	if flip_with_movement and _speed > walk_threshold and absf(moved.x) > 0.3:
		flip_h = moved.x < 0.0


func _process(delta: float) -> void:
	_time += delta
	var target_blend := 1.0 if _speed > walk_threshold else 0.0
	_walk_blend = move_toward(_walk_blend, target_blend, delta * 8.0)

	var idle_bob := sin(_time * idle_bob_speed) * idle_bob_height

	var phase := _time * walk_bob_speed
	var hop := absf(sin(phase))
	var walk_bob := -hop * walk_bob_height
	var walk_tilt := sin(phase) * deg_to_rad(walk_tilt_degrees)
	var stretch := (hop - 0.5) * walk_squash * _walk_blend

	var bob := lerpf(idle_bob, walk_bob, _walk_blend)
	position = _base_position + Vector2(0.0, bob) + _attack_offset
	rotation = _base_rotation + walk_tilt * _walk_blend + _attack_rotation
	scale = _base_scale * Vector2(1.0 - stretch, 1.0 + stretch) * _attack_scale


func _on_attacked(target: Node2D, attack: Attack) -> void:
	var dir := Vector2.LEFT if flip_h else Vector2.RIGHT
	if is_instance_valid(target):
		var to_target := target.global_position - _body.global_position
		if to_target.length() > 1.0:
			dir = to_target.normalized()
		if flip_with_movement and absf(to_target.x) > 1.0:
			flip_h = to_target.x < 0.0

	if _attack_tween != null and _attack_tween.is_valid():
		_attack_tween.kill()
	_attack_offset = Vector2.ZERO
	_attack_scale = Vector2.ONE
	_attack_rotation = 0.0

	if attack is RangeAttack:
		_play_projectile_jolt(dir)
		return

	_attack_tween = create_tween()
	_attack_tween.tween_property(self, "_attack_offset", -dir * windup_distance, windup_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(self, "_attack_offset", dir * lunge_distance, lunge_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_attack_tween.tween_property(self, "_attack_offset", Vector2.ZERO, recover_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_projectile_jolt(direction: Vector2) -> void:
	var tilt_direction := -1.0 if direction.x < 0.0 else 1.0
	_attack_scale = jolt_scale
	_attack_rotation = deg_to_rad(jolt_rotation_degrees) * tilt_direction

	_attack_tween = create_tween().set_parallel(true)
	_attack_tween.tween_property(self, "_attack_scale", Vector2.ONE.lerp(jolt_scale, -0.25), jolt_rebound_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(self, "_attack_rotation", -_attack_rotation * 0.35, jolt_rebound_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_attack_tween.chain().tween_property(self, "_attack_scale", Vector2.ONE, jolt_recover_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_attack_tween.tween_property(self, "_attack_rotation", 0.0, jolt_recover_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
