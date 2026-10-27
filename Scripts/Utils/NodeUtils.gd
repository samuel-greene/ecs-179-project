class_name NodeUtils

## Finds the closest node in a specific group relative to a source position.
static func get_closest_node_in_group(source_node: Node2D, group_name: StringName) -> Node2D:
	var nodes: Array[Node] = source_node.get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return null
	
	var closest_node: Node2D = null
	# Start with the highest possible float value
	var shortest_distance: float = INF 
	var source_pos: Vector2 = source_node.global_position
	
	for node in nodes:
		if node is Node2D:
			var distance: float = source_pos.distance_to(node.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				closest_node = node
				
	return closest_node
