extends Control
var currency: int = 100

const SHOP_ITEM = preload("res://Scenes/ShopItem.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# spacing so a hovered card has room to grow without touching the tabs/neighbours
	$ShopLayout.add_theme_constant_override("separation", 14)
	$ShopLayout/Content.add_theme_constant_override("h_separation", 16)
	$ShopLayout/Content.add_theme_constant_override("v_separation", 16)
	
	# connects the item and upgrades buttons
	$ShopLayout/Categories/ItemsButton.pressed.connect(items_button_pressed)
	$ShopLayout/Categories/UpgradesButton.pressed.connect(upgrade_button_pressed)
	$StartGameButton.pressed.connect(start_game_pressed)
	$StartGameButton.set_meta("ui_sound", "start")
	$ShopLayout/Categories/ItemsButton.set_meta("ui_sound", "tab")
	$ShopLayout/Categories/UpgradesButton.set_meta("ui_sound", "tab")
	
	#test items
	add_item("Alien Test Item","test", 50, preload("res://Sprites/alien_placeholder.png"), 0)
	add_item("Friendly Test Item","test", 100, preload("res://Sprites/friendly_placeholder.png"), 0)
	
	# test upgrade
	add_item("Coin Upgrade","test", 150, preload("res://Sprites/coin_placeholder.png"), 1)
	
	update_currency()
	_pulse_start_button()
	UISounds.play_music()
	show()
	
	#sets default visibility to the items
	filter_items(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
# open shop should be called every time the shop is opened, updates the user's number of coins
func open_shop():
	update_currency()
	show()
	
# this function adds a new item to the shop given a name, a description, a price, and 
# a path to where the icon is located.
# it also takes an item type. 0 is for items and 1 is for upgrades
func add_item(item_name: String, item_description: String, price: int, icon: Texture2D, item_type: int) -> void:
	var item = SHOP_ITEM.instantiate()
	$ShopLayout/Content.add_child(item)
	item.setup(item_name, item_description, price, icon, item_type)
	# bind(item) passes the card along so we can animate it on success/failure
	item.buy_pressed.connect(item_bought.bind(item))
	
# updates the number of coins the user has
func update_currency():
	$ShopLayout/header/Currency.text = str(currency) + " Coins"
	
	
# controls which items are visible.
func filter_items(type: int) -> void:
	var shown := 0
	for item in $ShopLayout/Content.get_children():
		if item.item_type == type:
			item.visible = true
			item.play_intro(shown * 0.06)  # cards appear one after another
			shown += 1
		else:
			item.visible = false
	
	
# upgrade button connector	
func upgrade_button_pressed() -> void:
	filter_items(1)

# items button connector	
func items_button_pressed() -> void:
	filter_items(0)
	
func item_bought(price: int, item: Node) -> void:
	if currency >= price:
		var old_value := currency
		currency -= price
		animate_currency(old_value, currency)
		item.play_success(price)
		UISounds.play("buy")
		_float_text_at_currency("-" + str(price), Color(1.0, 0.85, 0.2))
	else:
		item.play_fail()
		UISounds.play("error")
		_float_text_at_currency("Not enough coins", Color(1.0, 0.4, 0.4))
		print("Purchase unsuccessful")

func start_game_pressed() -> void:
	$StartGameButton.disabled = true
	UISounds.stop_music()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/battle_scene.tscn")


# counts the coin label up/down and gives it a little bounce
func animate_currency(from_value: int, to_value: int) -> void:
	var label: Label = $ShopLayout/header/Currency
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var count := create_tween()
	count.tween_method(func(value: float) -> void:
		label.text = str(int(round(value))) + " Coins",
		float(from_value), float(to_value), 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# small floating message that appears next to the coin counter and drifts down as it fades
func _float_text_at_currency(text: String, color: Color) -> void:
	var currency_label: Label = $ShopLayout/header/Currency
	var label := Label.new()
	label.text = text
	label.top_level = true  # containers ignore top-level nodes, so it stays where we put it
	label.z_index = 10
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)

	var start := currency_label.global_position + Vector2(currency_label.size.x + 10.0, 0.0)
	label.global_position = start

	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", start.y + 16.0, 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# gentle pulse on the Start Game button
func _pulse_start_button() -> void:
	var button: Button = $StartGameButton
	button.resized.connect(func() -> void: button.pivot_offset = button.size / 2.0)
	await get_tree().process_frame  # wait for layout so the pivot is correct
	button.pivot_offset = button.size / 2.0

	var tween := create_tween().set_loops()
	tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
