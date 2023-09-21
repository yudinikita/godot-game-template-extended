extends Control

@onready var video_bg := $Control/VideoStreamPlayer as VideoStreamPlayer
@onready var play_btn := $MC/MC2/HBC/VBC/VBC2/Play as Button
@onready var quit_btn := $MC/MC2/HBC/VBC/VBC2/Quit as Button
@onready var confirm_quit := $ConfirmQuit as Control
@onready var version := $MC/Version as Label


func _ready():
	SceneManager.reset_scene_manager()
	SceneManager.set_back_limit(-1)
	version.text = ProjectVersion.get_version()
	play_btn.grab_focus()


func _on_video_stream_player_finished():
	video_bg.play()


func _on_quit_button_up():
	confirm_quit.visible = true


func _on_confirm_quit_confirmed():
	SceneManager.change_scene(
		quit_btn.scene,
		quit_btn.fade_out_options,
		quit_btn.fade_in_options,
		quit_btn.general_options
	)


func _on_confirm_quit_canceled():
	confirm_quit.visible = false
