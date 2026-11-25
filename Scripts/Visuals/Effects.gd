extends RefCounted
class_name Effects

# Small one-shot effects, spawned into the current scene.

const PIXEL := 5.0  # matches the sprites' pixel scale


# a puff of square pixels flying outward
static func burst(at: Vector2, color: Color, amount: int = 6, speed: float = 90.0) -> void:
	var scene := _scene()
	if scene == null:
		return

	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.3
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.scale_amount_min = PIXEL
	particles.scale_amount_max = PIXEL
	particles.color = color
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particles.color_ramp = fade
	particles.z_index = 5

	scene.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	scene.get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)


# a square that pops and shrinks away
static func flash(at: Vector2, color: Color, size: float = PIXEL * 3.0) -> void:
	var scene := _scene()
	if scene == null:
		return

	var square := ColorRect.new()
	square.color = color
	square.size = Vector2(size, size)
	square.pivot_offset = square.size / 2.0
	square.z_index = 5
	scene.add_child(square)
	square.global_position = at - square.size / 2.0

	var tween := square.create_tween()
	tween.tween_property(square, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(square.queue_free)


# text that floats up and fades out
static func popup_text(at: Vector2, text: String, color: Color) -> void:
	var scene := _scene()
	if scene == null:
		return

	var label := Label.new()
	label.text = text
	label.z_index = 10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", 20)
	label.size = Vector2(60.0, 24.0)
	scene.add_child(label)
	label.global_position = at - label.size / 2.0

	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 30.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


static func _scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree else null
