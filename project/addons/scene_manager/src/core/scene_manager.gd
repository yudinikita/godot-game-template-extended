extends Node

## Signal fires when interactively loading a scene finishes
signal load_finished
## Signal fires when interactively loading a scene progress percentage updates
signal load_percent_changed(value: int)
## Signal fires when scene changes
signal scene_changed
## Signal fires when fade in starts
signal fade_in_started
## Signal fires when fade out starts
signal fade_out_started
## Signal fires when fade in finishes
signal fade_in_finished
## Signal fires when fade out finishes
signal fade_out_finished

const FADE: String = "fade"
const NO_COLOR: String = "no_color"
const BLACK: Color = Color(0, 0, 0)

var validation_manager: SceneManagerValidation
var stack_manager: SceneManagerStack
var _load_scene: String = ""
var _load_progress: Array = []
var _recorded_scene: String = ""

@onready var _first_time: bool = true
@onready var _in_transition: bool = false
@onready var _fade_color_rect: ColorRect = find_child("fade")
@onready var _animation_player: AnimationPlayer = find_child("animation_player")


class Options:
	# based checked seconds
	var fade_speed: float = 1
	var fade_pattern: String = FADE
	var smoothness: float = 0.1
	var inverted: bool = false


class GeneralOptions:
	var color: Color = BLACK
	var timeout: float = 0
	var clickable: bool = true
	var add_to_back: bool = true


# set current scene and get patterns from `addons/scene_manager/shader_patterns` folder
func _ready() -> void:
	validation_manager = SceneManagerValidation.new()
	stack_manager = SceneManagerStack.new()
	set_process(false)
	_set_starting_scene()
	SceneManagerUtils.get_patterns(validation_manager.patterns)


# used for interactive change scene
func _process(_delta: float):
	_handle_load_progress()
	_handle_load_status()


## Limits how much deep scene manager is allowed to record previous scenes which
## Affects in changing scene to `back`(previous scene) functionality
## Allowed `input` values:
## input = -1 => unlimited (default)
## input =  0 => we can not go back to any previos scenes
## input >  0 => we can go back to `input` or less previous scenes
func set_back_limit(input: int) -> void:
	stack_manager.set_back_limit(input)


## Resets the `_current_scene` and clears `_stack`
func reset_scene_manager() -> void:
	_set_starting_scene()
	stack_manager.clear_stack()


## Creates options for fade_out or fade_in transition
func create_options(
	fade_speed: float = 1.0,
	fade_pattern: String = "fade",
	smoothness: float = 0.1,
	inverted: bool = false
) -> Options:
	var options: Options = Options.new()
	options.fade_speed = fade_speed
	options.fade_pattern = fade_pattern
	options.smoothness = smoothness
	options.inverted = inverted
	return options


## Creates options for common properties in transition
## add_to_back means that you can go back to the scene if you
## change scene to `back` scene
func create_general_options(
	color: Color = Color(0, 0, 0),
	timeout: float = 0.0,
	clickable: bool = true,
	add_to_back: bool = true
) -> GeneralOptions:
	var options: GeneralOptions = GeneralOptions.new()
	options.color = color
	options.timeout = timeout
	options.clickable = clickable
	options.add_to_back = add_to_back
	return options


## Makes a fade_in transition for the first loaded scene in the game
func show_first_scene(fade_in_options: Options, general_options: GeneralOptions) -> void:
	if _first_time:
		_first_time = false
		_set_in_transition()
		_set_clickable(general_options.clickable)
		_set_pattern(fade_in_options, general_options)

		if SceneManagerUtils.timeout(general_options.timeout, _animation_player):
			await get_tree().create_timer(general_options.timeout).timeout

		if _fade_in(fade_in_options.fade_speed):
			await _animation_player.animation_finished
			fade_in_finished.emit()

		_set_clickable(true)
		_set_out_transition()


## Returns scene instance of passed scene key (blocking)
func create_scene_instance(key: String) -> Node:
	return get_scene(key).instantiate()


## Returns PackedScene of passed scene key (blocking)
func get_scene(key: String) -> PackedScene:
	validation_manager.validate_scene(key)
	var address = Scenes.scenes[key]["value"]
	ResourceLoader.load_threaded_request(address, "", true, ResourceLoader.CACHE_MODE_REUSE)
	return ResourceLoader.load_threaded_get(address)


## Changes current scene to the next scene
func change_scene(
	scene, fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions
) -> void:
	if validation_manager.is_valid_scene(scene) && can_change_scene():
		_first_time = false
		_set_in_transition()
		_set_clickable(general_options.clickable)
		_set_pattern(fade_out_options, general_options)

		if _fade_out(fade_out_options.fade_speed):
			await _animation_player.animation_finished
			fade_out_finished.emit()

		if _change_scene(scene, general_options.add_to_back):
			if !(scene is Node):
				await get_tree().node_added
			scene_changed.emit()

		if SceneManagerUtils.timeout(general_options.timeout, _animation_player):
			await get_tree().create_timer(general_options.timeout).timeout

			_animation_player.play(NO_COLOR, -1, 1, false)
		_set_pattern(fade_in_options, general_options)

		if _fade_in(fade_in_options.fade_speed):
			await _animation_player.animation_finished
			fade_in_finished.emit()

		_set_clickable(true)
		_set_out_transition()


## Check if we can change scene (if not in transition)
func can_change_scene() -> bool:
	return !_in_transition


## Change scene with no effect
func no_effect_change_scene(scene, hold_timeout: float = 0.0, add_to_back: bool = true):
	if validation_manager.is_valid_scene(scene) && can_change_scene():
		_first_time = false
		_set_in_transition()

		await get_tree().create_timer(hold_timeout).timeout

		if _change_scene(scene, add_to_back):
			if !(scene is Node):
				await get_tree().node_added

		_set_out_transition()


## Load a scene interactively and listen for loading status updates
## Cconnect to `load_percent_changed(value: int)` and `load_finished` signals
func load_scene_interactive(key: String) -> void:
	if validation_manager.safe_validate_scene(key):
		set_process(true)
		_load_scene = Scenes.scenes[key]["value"]
		ResourceLoader.load_threaded_request(
			_load_scene, "", true, ResourceLoader.CACHE_MODE_IGNORE
		)


## Get the loaded scene
## If scene is not loaded, blocks and waits until scene is ready. (acts blocking in code
## and may freeze your game, make sure scene is ready to get)
func get_loaded_scene(load_scene: String = "") -> PackedScene:
	if load_scene != "":
		return ResourceLoader.load_threaded_get(load_scene) as PackedScene
	return null


## Change the scene to the loaded scene
func change_scene_to_loaded_scene(
	fade_out_options: Options, fade_in_options: Options, general_options: GeneralOptions
) -> void:
	if _load_scene != "" && can_change_scene():
		var scene = ResourceLoader.load_threaded_get(_load_scene) as PackedScene
		if scene:
			_load_scene = ""
			change_scene(scene, fade_out_options, fade_in_options, general_options)


## Get the previous scene (scene before the current scene)
func get_previous_scene() -> String:
	return stack_manager.get_previous_scene()


## Get the previous scene at a specific index position
func get_previous_scene_at(index: int) -> String:
	return stack_manager.get_previous_scene_at(index)


## Pop from the back stack and return the previous scene (scene before the current scene)
func pop_previous_scene() -> String:
	return stack_manager.pop_stack()


## Get the number of scenes in the list of previous scenes
func previous_scenes_length() -> int:
	return stack_manager.get_stack_size()


## Record a scene key to be used for loading scenes to determine where to go next
## after getting loaded into the loading scene or for the next scene to know where to go next
func set_recorded_scene(key: String) -> void:
	validation_manager.validate_scene(key)
	_recorded_scene = key


## Get the recorded scene
func get_recorded_scene() -> String:
	return _recorded_scene


## Set the current scene to the starting point (used for the `back` functionality)
func _set_starting_scene() -> void:
	var root_key: String = get_tree().current_scene.scene_file_path
	var current_scene = SceneManagerUtils.find_scene_key(root_key)

	stack_manager.set_current_scene(current_scene)

	assert(
		current_scene != "",
		"Scene Manager Error: loaded scene is not defined in scene manager tool."
	)


func _handle_load_progress() -> void:
	var prev_percent: int = 0
	if len(_load_progress) != 0:
		prev_percent = int(_load_progress[0] * 100)
	ResourceLoader.load_threaded_get_status(_load_scene, _load_progress)
	var next_percent: int = int(_load_progress[0] * 100)
	if prev_percent != next_percent:
		load_percent_changed.emit(next_percent)


func _handle_load_status() -> void:
	var status := ResourceLoader.load_threaded_get_status(_load_scene, _load_progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		_load_progress = []
		load_finished.emit()
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
	else:
		assert(false, "for some reason, loading failed")


## Change the scene to the previous scene
func _back() -> bool:
	var pop: String = stack_manager.pop_stack()
	if pop:
		get_tree().change_scene_to_file(Scenes.scenes[pop]["value"])
		return true
	return false


## Restart the same scene
func _refresh() -> bool:
	get_tree().change_scene_to_file(Scenes.scenes[stack_manager.get_current_scene()]["value"])
	return true


## Check different states of the scene and perform actual transitions
func _change_scene(scene, add_to_back: bool) -> bool:
	var success: bool = false

	if scene is PackedScene:
		success = _change_to_packed_scene(scene, add_to_back)
	elif scene is Node:
		success = _change_to_node_scene(scene, add_to_back)
	else:
		success = _change_to_other_scene(scene, add_to_back)

	return success


func _change_to_packed_scene(scene: PackedScene, add_to_back: bool) -> bool:
	get_tree().change_scene_to_packed(scene)

	var path: String = scene.resource_path
	var found_key: String = SceneManagerUtils.find_scene_key(path)

	if add_to_back && found_key != "":
		stack_manager.append_stack(found_key)

	return true


func _change_to_node_scene(scene: Node, add_to_back: bool) -> bool:
	var root = get_tree().get_root()
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scene)
	get_tree().set_current_scene(scene)

	var path: String = scene.scene_file_path
	var found_key: String = SceneManagerUtils.find_scene_key(path)

	if add_to_back && found_key != "":
		stack_manager.append_stack(found_key)

	return true


func _change_to_other_scene(scene, add_to_back: bool) -> bool:
	var success: bool = false

	match scene:
		"back":
			success = _back()

		"null", "ignore", "":
			success = false

		"reload", "refresh", "restart":
			success = _refresh()

		"exit", "quit":
			get_tree().quit(0)

		_:
			get_tree().change_scene_to_file(Scenes.scenes[scene]["value"])
			if add_to_back:
				stack_manager.append_stack(scene)
			success = true

	return true


## Fade in with the specified speed (unit is in seconds)
func _fade_in(speed: float) -> bool:
	if speed == 0:
		return false
	fade_in_started.emit()
	_animation_player.play(FADE, -1, 1 / speed, false)
	return true


## Fade out with the specified speed (unit is in seconds)
func _fade_out(speed: float) -> bool:
	if speed == 0:
		return false
	fade_out_started.emit()
	_animation_player.play(FADE, -1, -1 / speed, true)
	return true


## Activates `in_transition` mode
func _set_in_transition() -> void:
	_in_transition = true


## Deactivates `in_transition` mode
func _set_out_transition() -> void:
	_in_transition = false


## Enable or disable clickability of the menu during transitions
func _set_clickable(clickable: bool) -> void:
	if clickable:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		_fade_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP


## Set properties for transitions
func _set_pattern(options: Options, general_options: GeneralOptions) -> void:
	if options.fade_pattern not in validation_manager.patterns:
		options.fade_pattern = "fade"

	var fade_material = _fade_color_rect.material
	var fade_color = Vector3(
		general_options.color.r, general_options.color.g, general_options.color.b
	)

	if options.fade_pattern == "fade":
		fade_material.set_shader_parameter("linear_fade", true)
		fade_material.set_shader_parameter("color", fade_color)
		fade_material.set_shader_parameter("custom_texture", null)
	else:
		fade_material.set_shader_parameter("linear_fade", false)
		fade_material.set_shader_parameter(
			"custom_texture", validation_manager.patterns[options.fade_pattern]
		)
		fade_material.set_shader_parameter("inverted", options.inverted)
		fade_material.set_shader_parameter("smoothness", options.smoothness)
		fade_material.set_shader_parameter("color", fade_color)
