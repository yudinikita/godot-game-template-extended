extends Button

@export_category("Scene Manager")
@export var scene: String

@export_subgroup("General")
## color for the whole transition
@export var color: Color = Color(0, 0, 0)
## between this scene and next scene, there would be a gap which can take much longer that usual
@export var timeout: float = 0.0
## makes the scene behind the transition visuals clickable or not
@export var clickable: bool = false
## if true, you can go back to current scene after changing scene to next scene
@export var add_to_back: bool = true

@export_subgroup("Fade")
@export_exp_easing var fade_out_speed: float = 1.0
@export_exp_easing var fade_in_speed: float = 1.0
@export_enum(
	"fade",
	"circle",
	"crooked_tiles",
	"curtains",
	"diagonal",
	"dirt",
	"horizontal",
	"pixel",
	"radial",
	"scribbles",
	"splashed_dirt",
	"squares",
	"vertical"
)
var fade_out_pattern: String = "fade"
@export_enum(
	"fade",
	"circle",
	"crooked_tiles",
	"curtains",
	"diagonal",
	"dirt",
	"horizontal",
	"pixel",
	"radial",
	"scribbles",
	"splashed_dirt",
	"squares",
	"vertical"
)
var fade_in_pattern: String = "fade"
@export_range(0, 1, 0.1) var fade_out_smoothness = 0.1  # (float, 0, 1)
@export_range(0, 1, 0.1) var fade_in_smoothness = 0.1  # (float, 0, 1)
@export var fade_out_inverted: bool = false
@export var fade_in_inverted: bool = false

@onready var fade_out_options = SceneManager.create_options(
	fade_out_speed, fade_out_pattern, fade_out_smoothness, fade_out_inverted
)
@onready var fade_in_options = SceneManager.create_options(
	fade_in_speed, fade_in_pattern, fade_in_smoothness, fade_in_inverted
)
@onready
var general_options = SceneManager.create_general_options(color, timeout, clickable, add_to_back)


func _ready() -> void:
	var fade_in_first_scene_options = SceneManager.create_options(1, "fade")
	var first_scene_general_options = SceneManager.create_general_options(
		Color(0.165, 0.208, 0.255), 1, false
	)
	SceneManager.show_first_scene(fade_in_first_scene_options, first_scene_general_options)
	# code breaks if scene is not recognizable
	SceneManager.validation_manager.validate_scene(scene)
	# code breaks if pattern is not recognizable
	SceneManager.validation_manager.validate_pattern(fade_out_pattern)
	SceneManager.validation_manager.validate_pattern(fade_in_pattern)


func _on_button_button_up():
	if SceneManager.can_change_scene():
		SceneManager.change_scene(scene, fade_out_options, fade_in_options, general_options)


func _on_reset_button_up():
	SceneManager.reset_scene_manager()


func _on_loading_scene_button_up():
	if SceneManager.can_change_scene():
		SceneManager.set_recorded_scene(scene)
		SceneManager.change_scene("loading_scene", fade_out_options, fade_in_options, general_options)
