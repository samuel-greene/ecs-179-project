extends Marker2D

const FRIENDLY_V1 = preload("res://Scenes/Friendlies/Friend_v1.tscn")

var spawn_positions = [
	Vector2(-250, -150),
	Vector2(150, 150),
	Vector2(150, -150),
	Vector2(-150, 150)
]

func _ready():
	spawn_positions.shuffle()
	
	for i in range(GameData.friendly_count - 1):
		var friendly = FRIENDLY_V1.instantiate()
		friendly.name = "PurchasedFriendly_" + str(i + 1)
		
		add_child(friendly)
		friendly.global_position = global_position + spawn_positions[i]
