class_name SceneManagerStack
extends Node

@onready var _current_scene: String = ""
@onready var _stack: Array = []
@onready var _stack_limit: int = -1


func set_current_scene(input: String) -> void:
	_current_scene = input


func get_current_scene() -> String:
	return _current_scene


func set_back_limit(input: int) -> void:
	assert(input >= -1, "Input must be greater than or equal to -1")
	_stack_limit = input

	if input == 0:
		_stack.clear()
	elif input > 0:
		if input <= len(_stack):
			for i in range(len(_stack) - input):
				_stack.pop_front()


## Clears `_stack`
func clear_stack() -> void:
	_stack.clear()


## Get the previous scene (scene before the current scene)
func get_previous_scene() -> String:
	return _stack[len(_stack) - 1]


## Get the previous scene at a specific index position
func get_previous_scene_at(index: int) -> String:
	if index < len(_stack):
		return _stack[index]
	return ""


## Pop the most recently added scene from the `_stack`
func pop_stack() -> String:
	var pop = _stack.pop_back()
	if pop:
		_current_scene = pop
	return _current_scene


## Get the number of scenes in the list of previous scenes
func get_stack_size() -> int:
	return len(_stack)


## Add current scene to `_stack`
func append_stack(key: String) -> void:
	if _stack_limit == -1:
		_stack.append(_current_scene)
	elif _stack_limit > 0:
		if _stack_limit <= len(_stack):
			for i in range(len(_stack) - _stack_limit + 1):
				_stack.pop_front()
			_stack.append(_current_scene)
		else:
			_stack.append(_current_scene)
	_current_scene = key
