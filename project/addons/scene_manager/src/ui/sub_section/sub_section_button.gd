@tool
extends Button


# Can drop here
func can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return get_parent().get_parent().can_drop_data(at_position, data)


# Drop here
func drop_data(at_position: Vector2, data: Variant) -> void:
	get_parent().get_parent().drop_data(at_position, data)
