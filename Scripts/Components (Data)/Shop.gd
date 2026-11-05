extends Control
var currency: int = 100

const SHOP_ITEM = preload("res://Scenes/ShopItem.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# connects the item and upgrades buttons
	$ShopLayout/Categories/ItemsButton.pressed.connect(items_button_pressed)
	$ShopLayout/Categories/UpgradesButton.pressed.connect(upgrade_button_pressed)
	
	#test items
	add_item("Alien Test Item","test", 50, preload("res://Sprites/alien_placeholder.png"), 0)
	add_item("Friendly Test Item","test", 100, preload("res://Sprites/friendly_placeholder.png"), 0)
	
	# test upgrade
	add_item("Coin Upgrade","test", 150, preload("res://Sprites/coin_placeholder.png"), 1)
	
	update_currency()
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
		
	
# updates the number of coins the user has
func update_currency():
	$ShopLayout/header/Currency.text = str(currency) + " Coins"
	
	
# controls which items are visible.
func filter_items(type: int) -> void:
	for item in $ShopLayout/Content.get_children():
		if item.item_type == type:
			item.visible = true
		else:
			item.visible = false
	
	
# upgrade button connector	
func upgrade_button_pressed() -> void:
	filter_items(1)

# items button connector	
func items_button_pressed() -> void:
	filter_items(0)
	
