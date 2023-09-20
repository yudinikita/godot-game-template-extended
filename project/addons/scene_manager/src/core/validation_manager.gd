## Class for validating scenes and patterns
class_name ValidationManager
extends Node

var _patterns: Dictionary = {}
var _reserved_keys: Array = [
	"back", "null", "ignore", "refresh", "reload", "restart", "exit", "quit"
]


## Validates passed scene key
func validate_scene(key: String) -> void:
	assert(
		is_valid_key(key) && !key.begins_with("_"),
		"Scene Manager Error: `%s` key for scene is not recognized, please double check." % key
	)


## Validates passed scene key
func safe_validate_scene(key: String) -> bool:
	return is_valid_key(key) && !key.begins_with("_")


## Validates passed pattern key
func validate_pattern(key: String) -> void:
	assert(is_valid_pattern(key), _get_error_massage(key))


## Validates passed pattern key
func safe_validate_pattern(key: String) -> bool:
	return is_valid_pattern(key)


## Check if the scene key is valid
func is_valid_key(key: String) -> bool:
	return key in _reserved_keys || key == "" || Scenes.scenes.has(key)


## Check if the pattern key is valid
func is_valid_pattern(key: String) -> bool:
	var keys := _patterns.keys()
	return key in _patterns || key == "fade" || key == ""


func is_valid_scene(scene) -> bool:
	return (
		scene is PackedScene
		|| scene is Node
		|| (typeof(scene) == TYPE_STRING && safe_validate_scene(scene))
	)


## Generate error message for invalid pattern key
func _get_error_massage(key: String) -> String:
	var error_part1 := (
		"Scene Manager Error: `%s` key for shader pattern is not recognizable, please double check.\n"
		% key
	)
	var keys := _patterns.keys()
	var string_keys := ""

	for i in range(0, keys.size()):
		if i == 0:
			string_keys = '"%s"' % keys[0]
			continue
			string_keys += ', "%s"' % keys[i]

	var error_part2 := 'Acceptable keys are "%s" , "fade".' % string_keys

	return error_part1 + error_part2
