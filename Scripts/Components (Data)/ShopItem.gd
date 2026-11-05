extends PanelContainer

var item_name: String
var item_price: int
var item_description: String
var item_icon: Texture2D

# item_type, 0 for item, 1 for upgrade
var item_type: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
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
