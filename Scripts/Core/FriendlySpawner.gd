extends Marker2D

const FRIENDLY_V1 = preload("res://Scenes/Friendlies/Friend_v1.tscn")
## Distance (px) between extra friendlies once all preset spots are used.
const EXTRA_SPACING := 50.0

var spawn_positions = [
	Vector2(-250, -150),
	Vector2(150, 150),
	Vector2(150, -150),
	Vector2(-150, 150)
]

func _ready():
	spawn_positions.shuffle()

	if GameData.friendly_count > 1:
		UISounds.play("friendly_spawn", 0.05)

	for i in range(GameData.friendly_count - 1):
		var friendly = FRIENDLY_V1.instantiate()
		friendly.name = "PurchasedFriendly_" + str(i + 1)
		
		add_child(friendly)
		friendly.global_position = global_position + _get_spawn_offset(i)


# The first friendlies use the preset spots. Once those run out, extras cycle
# back through them, placed in a widening ring around each spot so they don't
# start on top of each other.
func _get_spawn_offset(index: int) -> Vector2:
	var base: Vector2 = spawn_positions[index % spawn_positions.size()]
	var ring := floori(float(index) / spawn_positions.size())
	if ring == 0:
		return base
	# 2.4 rad (the golden angle) spreads the extras evenly around each spot.
	return base + Vector2.from_angle(index * 2.4) * EXTRA_SPACING * ring
