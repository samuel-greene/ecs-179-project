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

@export_group("Hit Reaction")
## Seconds the white flash takes to fade after taking damage
@export var flash_time: float = 0.12
## Squash applied for a moment when hit (x wider, y shorter)
@export var hit_squash: Vector2 = Vector2(1.2, 0.8)
## How far (px) the sprite is knocked in a random direction when hit
@export var hit_shake: float = 3.0

@export_group("Death")
## Seconds the death "ghost" takes to shrink and fade
@export var death_time: float = 0.4
@export var burst_color: Color = Color(0.55, 1.0, 0.45)
@export var burst_amount: int = 14
@export var burst_speed_min: float = 60.0
@export var burst_speed_max: float = 150.0

# Turns the sprite solid white by the "flash" amount. Built in code so there is no extra file.
const FLASH_SHADER := """
shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
"""
static var _flash_shader: Shader

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
var _hit_offset: Vector2 = Vector2.ZERO
var _hit_scale: Vector2 = Vector2.ONE
var _hit_tween: Tween
var _flash_tween: Tween
var _flash_material: ShaderMaterial


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

	# flash material (only if the sprite doesn't already have its own material)
	if material == null:
		_flash_material = _make_flash_material()
		material = _flash_material

	# react to damage and death through the unit's Health node
	var health := _body.get_node_or_null("Health") as Health
	if health != null:
		health.received_damage.connect(_on_damaged)
		health.died.connect(_on_died)


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
	position = _base_position + Vector2(0.0, bob) + _attack_offset + _hit_offset
	rotation = _base_rotation + walk_tilt * _walk_blend + _attack_rotation
	scale = _base_scale * Vector2(1.0 - stretch, 1.0 + stretch) * _attack_scale * _hit_scale


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


# ---------- hit reaction ----------

func _on_damaged(_amount: float) -> void:
	_flash()

	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_scale = hit_squash
	_hit_offset = Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)).normalized() * hit_shake

	_hit_tween = create_tween().set_parallel(true)
	_hit_tween.tween_property(self, "_hit_scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(self, "_hit_offset", Vector2.ZERO, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _flash() -> void:
	if _flash_material == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_material.set_shader_parameter("flash", 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_method(_set_flash, 1.0, 0.0, flash_time)


func _set_flash(value: float) -> void:
	_flash_material.set_shader_parameter("flash", value)


func _make_flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = FLASH_SHADER
	var flash_material := ShaderMaterial.new()
	flash_material.shader = _flash_shader
	return flash_material


# ---------- death ----------

# The unit is freed right after it dies, so the effect is a separate "ghost" copy
# of the sprite (plus particles) added to the scene, which cleans itself up.
func _on_died() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = texture
	ghost.centered = centered
	ghost.offset = offset
	ghost.flip_h = flip_h
	ghost.flip_v = flip_v
	ghost.hframes = hframes
	ghost.vframes = vframes
	ghost.frame = frame
	ghost.region_enabled = region_enabled
	ghost.region_rect = region_rect
	ghost.z_index = 5
	var ghost_material := _make_flash_material()
	ghost_material.set_shader_parameter("flash", 1.0)  # starts solid white
	ghost.material = ghost_material
	scene.add_child(ghost)
	ghost.global_transform = global_transform

	var start_scale := ghost.scale
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "scale", start_scale * 1.25, 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(0.05, 0.05), death_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(ghost, "modulate:a", 0.0, death_time)
	tween.tween_callback(ghost.queue_free)

	_spawn_burst(scene, global_position)


func _spawn_burst(scene: Node, spawn_position: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 1.0
	particles.amount = burst_amount
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = burst_speed_min
	particles.initial_velocity_max = burst_speed_max
	particles.gravity = Vector2(0.0, 220.0)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0  # no texture, so these are 2-4 px squares
	particles.color = burst_color
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	particles.z_index = 5

	scene.add_child(particles)
	particles.global_position = spawn_position
	particles.emitting = true
	scene.get_tree().create_timer(particles.lifetime + 0.3).timeout.connect(particles.queue_free)
