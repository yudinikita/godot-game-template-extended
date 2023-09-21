extends Control

@export_category("Scene Manager")
@export var color: Color = Color(0, 0, 0)
@export var timeout: float = 0.0
@export var clickable: bool = false
@export var add_to_back: bool = true
@export var open_over_scene: bool = false

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

var is_finished: bool = false

@onready var progress: ProgressBar = find_child("Progress")
@onready var progress_label: Label = find_child("ProgressLabel")
@onready var skip_anim: AnimationPlayer = find_child("AnimationPlayer")
@onready var video_bg := $Control/VideoStreamPlayer as VideoStreamPlayer


func _ready():
	SceneManager.load_percent_changed.connect(Callable(self, "percent_changed"))
	SceneManager.load_finished.connect(Callable(self, "loading_finished"))
	SceneManager.load_scene_interactive(SceneManager.get_recorded_scene())
	skip_anim.play("flash")


func _input(event):
	if is_finished:
		if (
			event is InputEventMouseButton
			or event is InputEventScreenTouch
			or event is InputEventKey
		):
			next_scene()


func percent_changed(number: int) -> void:
	progress.value = number
	progress_label.text = str(number) + "%"


func loading_finished() -> void:
	is_finished = true


func next_scene():
	var fade_out_options = SceneManager.create_options(
		fade_out_speed, fade_out_pattern, fade_out_smoothness, fade_out_inverted
	)
	var fade_in_options = SceneManager.create_options(
		fade_in_speed, fade_in_pattern, fade_in_smoothness, fade_in_inverted
	)
	var general_options = SceneManager.create_general_options(
		color, timeout, clickable, add_to_back, open_over_scene
	)
	SceneManager.change_scene_to_loaded_scene(fade_out_options, fade_in_options, general_options)


func _on_video_stream_player_finished():
	video_bg.play()
