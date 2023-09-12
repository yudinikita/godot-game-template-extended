extends AweSplashScreen

@export var splash_duration := 1.0
@export var prepare_move_other_screen = 0.2

@onready var video_splash := $CanvasLayer/Control/VideoStreamPlayer as VideoStreamPlayer
@onready var logo_splash := $CanvasLayer/Control/Logo as TextureRect
@onready var video_timer := $VideoPlayTimer as Timer


func get_splash_screen_name() -> String:
	return "GGTE"


func _on_video_play_timer_timeout():
	video_splash.play()
	logo_splash.visible = true


func _on_video_stream_player_finished():
	gd.sequence([
		gd.perform("finished_animation", self)
	]).start(self)
