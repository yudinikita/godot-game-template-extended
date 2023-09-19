extends Control

signal ended


@export_category("Credits")
## The credits file (formatted like a INI file (more info inside README.md))
@export_file var credits_file: String

@export_group("Speed")
## Speed of scrolling
@export_exp_easing var speed: float = 40
## Text acceleration rate
@export_exp_easing var text_speed_up: float = 10
## Text slowdown rate
@export_exp_easing var text_speed_down: float = 10
## How fast the text will go when completed
@export_exp_easing var skip_speed: float = 100

@export_group("Styles")
@export_subgroup("Background")
## The color of the background (covered if there is a video)
@export var background_color := Color.BLACK
## Video to play in background instead of having just a solid color
@export var background_video: VideoStream
## Do you want the video to be restarted once finished?
@export var loop_video = true

@export_subgroup("Text")
## Color of the text on left side
@export var titles_color := Color.GRAY
## Color of the text on right side
@export var names_color := Color.WHITE
## Custom font
@export var custom_font: Font
## Space between left and right sides
@export var margin: int = 6

@export_group("Music")
## Playlist of music to play during credits scroll
@export var music_playlist: Array[AudioStream]
## Do you want the playlist to be restarted once finished?
@export var loop_playlist := false

@export_group("Controls")
## Do you want to enable go faster, go slower, pause and reverse controls with ui_actions?
@export var enable_controls := true
@export var speed_up_control := "ui_up"
@export var slow_down_control := "ui_down"
## Do you want to be able to skip all the credits by pressing ui_accept?
@export var enable_skip := true
@export var skip_control := "ui_accept"

@export_group("Behavior")
## The next scene to load once the scroll ended
@export var next_scene := "back"
## If true and there is no next_scene selected and quit_on_end is false, once the scroll ended the node will be destroyed
@export var destroy_on_end := false

## The size of the window
var view_size
## To keep track of the original speed
var regular_speed
## True if all the credits have been scrolled off the screen
var done := false
var file: FileAccess
var credits: String
var playlist_index := 0
var is_first_frame = true
var can_change_scene = false

## Container of all scrolling nodes
@onready var scrolling_container := $ScrollingContainer as VBoxContainer
## Container of titles and names
@onready var scrolling_text := $ScrollingContainer/ScrollingText as HBoxContainer
## Titles (the text on left side)
@onready var titles := $ScrollingContainer/ScrollingText/MarginTitles/Titles as Label
## Names (the text on right side)
@onready var names := $ScrollingContainer/ScrollingText/MarginNames/Names as Label
## The back button
@onready var back_btn := $Back as Button


func _ready():
	view_size = get_viewport().size
	scrolling_text.position.y = view_size.y
	regular_speed = speed

	SceneManager.fade_in_finished.connect(Callable(self, "_scene_finish_loaded"))

	_set_background_video()
	_set_colors()
	_set_custom_font()
	_set_margin()
	_play_playlist()
	_verify_credits_file()
	_parse_credits_file()

func _process(delta):
	# For some reason the position of the container is shifted once displayed.
	# This workaround fix it
	if is_first_frame:
		view_size = get_viewport().size
		scrolling_container.position.y = view_size.y
		is_first_frame = false

	if not done:
		_scroll_container(delta)
		_check_scroll_end()


func _input(event):
	if not done:
		_control_text_speed(event)
		_skip_credits(event)


func _scene_finish_loaded():
	can_change_scene = true


func _set_colors():
	$Background.color = background_color
	titles.add_theme_color_override("font_color", titles_color)
	names.add_theme_color_override("font_color", names_color)


## Set background video if there is one, otherwise delete the useless node
func _set_background_video():
	if background_video != null:
		$BackgroundVideo.stream = background_video
		$BackgroundVideo.play()
	else:
		$BackgroundVideo.queue_free()


## Set the custom font (if there is one)
func _set_custom_font():
	if custom_font != null:
		titles.add_theme_font_override("font", custom_font)
		names.add_theme_font_override("font", custom_font)


## Set the margin (the space between left and right panels)
func _set_margin():
	@warning_ignore("integer_division")
	$ScrollingContainer/ScrollingText/MarginTitles.add_theme_constant_override("margin_right", margin / 2)
	@warning_ignore("integer_division")
	$ScrollingContainer/ScrollingText/MarginNames.add_theme_constant_override("margin_left", margin / 2)


func _play_playlist():
	# If the playlist has at list one track, play it
	if music_playlist.size() > 0 and music_playlist[playlist_index] != null:
		playlist_track(playlist_index)


func _verify_credits_file():
	# Verify if a credits file has been provided
	if credits_file.is_empty():
		push_error("At least one credits file must be provided.")
		assert(false)

	# Verify if credits file exists
	if not FileAccess.file_exists(credits_file):
		push_error("Credits file does not exist.")
		assert(false)

	# Well, open the credits file and read it
	file = FileAccess.open(credits_file, FileAccess.READ)
	credits = file.get_as_text()
	file.close()


## Parse the credits file and update the titles and names
func _parse_credits_file():
	var lines = credits.split("\n")
	var previousLineEmpty = false

	for line in lines:
		line = line.strip_edges()

		if line == "":
			titles.text += "\n"
			names.text += "\n"

			if previousLineEmpty:
				titles.text += "\n"
				names.text += "\n"

			previousLineEmpty = true
		else:
			if line.begins_with("[") and line.ends_with("]"):
				if previousLineEmpty:
					titles.text += "\n"
					names.text += "\n"

				line = line.substr(1, line.length() - 2)
				line = line.replace("[", "").replace("]", "") # Remove brackets from the line
				titles.text += tr(line)
			else:
				names.text += line + "\n"
				titles.text += "\n"

			previousLineEmpty = false


func _scroll_container(delta):
	# If the scroll is not yet ended, scroll the text
	if scrolling_container.position.y + scrolling_container.size.y > 0:
		scrolling_container.position.y -= speed * delta


func _check_scroll_end():
	# If the scrolling is ended, call the end function
	if scrolling_container.position.y + scrolling_container.size.y <= 0:
		end()


func _control_text_speed(event: InputEvent) -> void:
	# If controls are enabled, adjust the text scrolling speed
	if enable_controls:
		if event.is_action_pressed(slow_down_control):
			speed -= text_speed_down * event.get_action_strength(slow_down_control)
		if event.is_action_pressed(speed_up_control):
			speed += text_speed_up * event.get_action_strength(speed_up_control)

		# Reset the speed to its regular value when the buttons are released
		if event.is_action_released(slow_down_control) or event.is_action_released(speed_up_control):
			speed = regular_speed


func _skip_credits(event: InputEvent) -> void:
	# If skipping is enabled, allow the player to skip the credits
	if enable_skip and can_change_scene:
		if event.is_action_pressed(skip_control):
			speed *= skip_speed


## On video end, replay it if it's enable the loop
func _on_background_video_finished():
	if loop_video:
		$BackgroundVideo.play()


## Function to change playing track of playlist
func playlist_track(index):
	if 0 <= index and index < music_playlist.size():
		music_playlist[index].loop = false
		$MusicPlayer.stream = music_playlist[index]
		$MusicPlayer.play()
		playlist_index = index


## On track end, check if there is another track in the playlist after it
## if not, and the playlist loop is enabled, restart the playlist
func _on_music_player_finished():
	if playlist_index + 1 < music_playlist.size():
		playlist_track(playlist_index + 1)
	elif loop_playlist:
		playlist_index = 0
		playlist_track(playlist_index)


## Use this function to stop all
func end():
	if can_change_scene:
		emit_signal("ended")  # Emit a signal to make easy for programmers to connect other things to this
		done = true  # And a var, to make things even more easy to connect

		back_btn.scene = next_scene
		back_btn.emit_signal("button_up")
	elif destroy_on_end:
		self.queue_free()
