extends PanelContainer

signal buy_pressed(item_price: int)

const HOVER_SCALE := Vector2(1.04, 1.04)
const PRESS_SCALE := Vector2(0.95, 0.95)
const HOVER_COLOR := Color(1.12, 1.12, 1.12)

var item_name: String
var item_price: int
var item_description: String
var item_icon: Texture2D

# item_type, 0 for item, 1 for upgrade
var item_type: int

var _hovering: bool = false
var _pressing: bool = false
var _scale_tween: Tween
var _color_tween: Tween
var _icon_tween: Tween
var _shake_tween: Tween

@onready var _icon: TextureRect = $VBoxContainer/CenterContainer/Icon


func _ready() -> void:
	$VBoxContainer/BuyButton.pressed.connect(item_bought)
	$VBoxContainer/BuyButton.button_down.connect(_on_buy_down)
	$VBoxContainer/BuyButton.button_up.connect(_on_buy_up)
	# scale and rotation happen around the middle of the card / icon
	resized.connect(_update_pivots)
	_icon.resized.connect(_update_pivots)
	_update_pivots()


# Hover is checked by position instead of mouse_entered/exited, because those
# fire "exit" whenever the mouse moves over the Buy button inside the card.
func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		if _hovering:
			_hovering = false
			scale = Vector2.ONE
			z_index = 0
		return

	var rect := get_global_rect()
	if _hovering:
		rect = rect.grow(6.0)  # a little slack so the edge doesn't flicker
	var now_hovering := rect.has_point(get_global_mouse_position())
	if now_hovering != _hovering:
		_hovering = now_hovering
		z_index = 1 if _hovering else 0  # draw the hovered card over its neighbours
		_tween_scale(_target_scale(), 0.12)
		_tween_color(_rest_color(), 0.12)
		_set_icon_wiggle(_hovering)


# sets up the information for the item and updates the graphics accordingly
func setup(i_name:String, description:String, price: int, icon: Texture2D, type: int) -> void:
	item_name = i_name
	item_price = price
	item_description = description
	item_icon = icon
	item_type = type

	$VBoxContainer/CenterContainer/Icon.texture = item_icon
	$VBoxContainer/Name.text = item_name
	$VBoxContainer/Price.text = str(item_price) + " Coins"
	$VBoxContainer/Description.text = item_description

func item_bought():
	buy_pressed.emit(item_price)


# ---------- animations ----------

## Cards fade and pop in. Pass a delay so a row of cards appears one by one.
func play_intro(delay: float = 0.0) -> void:
	_kill(_color_tween)
	_kill(_scale_tween)
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.85, 0.85)

	_color_tween = create_tween()
	_color_tween.tween_property(self, "modulate", _rest_color(), 0.2).set_delay(delay)
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", _target_scale(), 0.28) \
		.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Called by the shop when the purchase went through.
func play_success(_price: int) -> void:
	_flash(Color(1.7, 1.7, 1.3))

	_kill(_scale_tween)
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", _target_scale(), 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_icon.scale = Vector2(1.4, 1.4)
	create_tween().tween_property(_icon, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Called by the shop when the player can't afford it.
func play_fail() -> void:
	_flash(Color(1.6, 0.5, 0.5))

	# Containers control a card's position, so wobble its rotation instead.
	_kill(_shake_tween)
	_shake_tween = create_tween()
	for angle in [4.0, -4.0, 3.0, -3.0, 1.5, 0.0]:
		_shake_tween.tween_property(self, "rotation", deg_to_rad(angle), 0.04)


# ---------- helpers ----------

func _on_buy_down() -> void:
	_pressing = true
	_tween_scale(_target_scale(), 0.06)


func _on_buy_up() -> void:
	_pressing = false
	_tween_scale(_target_scale(), 0.22, Tween.TRANS_BACK)


func _target_scale() -> Vector2:
	if _pressing:
		return PRESS_SCALE
	return HOVER_SCALE if _hovering else Vector2.ONE


func _rest_color() -> Color:
	return HOVER_COLOR if _hovering else Color.WHITE


func _update_pivots() -> void:
	pivot_offset = size / 2.0
	_icon.pivot_offset = _icon.size / 2.0


func _tween_scale(target: Vector2, time: float,
		trans: Tween.TransitionType = Tween.TRANS_QUAD) -> void:
	_kill(_scale_tween)
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, time) \
		.set_trans(trans).set_ease(Tween.EASE_OUT)


func _tween_color(target: Color, time: float) -> void:
	_kill(_color_tween)
	_color_tween = create_tween()
	_color_tween.tween_property(self, "modulate", target, time)


func _flash(color: Color) -> void:
	_kill(_color_tween)
	modulate = color
	_color_tween = create_tween()
	_color_tween.tween_property(self, "modulate", _rest_color(), 0.3)


func _set_icon_wiggle(on: bool) -> void:
	_kill(_icon_tween)
	_icon_tween = create_tween()
	if on:
		_icon_tween.set_loops()
		_icon_tween.tween_property(_icon, "rotation", deg_to_rad(5.0), 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_icon_tween.tween_property(_icon, "rotation", deg_to_rad(-5.0), 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		_icon_tween.tween_property(_icon, "rotation", 0.0, 0.15)


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
