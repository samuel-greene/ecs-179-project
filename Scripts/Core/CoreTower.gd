extends Tower

## Seconds to wait after the core dies before switching to the shop,
## so the game over sound has time to play.
@export var shop_delay: float = 1.5


# Replaces Tower's death handler, so only the game over sound plays
# (not the regular tower_destroyed sound as well).
func _on_health_died() -> void:
	UISounds.play("core_destroyed")
	# The tree's timer keeps running after this tower is freed.
	var tree := get_tree()
	tree.create_timer(shop_delay).timeout.connect(
		tree.change_scene_to_file.bind("res://Scenes/Shop.tscn"))
	queue_free()
