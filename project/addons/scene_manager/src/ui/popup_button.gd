@tool
extends Button


## Get and return drag data from the parent control
func _get_drag_data(at_position: Vector2) -> Variant:
	return get_parent().get_drag_data(at_position)
