extends Control

@onready var video_bg := $CanvasLayer/Control/VideoStreamPlayer as VideoStreamPlayer
@onready var general_btn := $CanvasLayer/MC/VBoxContainer/MiddleContainer/HBC/VBC/Buttons/General as Button


func _ready():
	general_btn.grab_focus()


func _on_video_stream_player_finished():
	video_bg.play()
