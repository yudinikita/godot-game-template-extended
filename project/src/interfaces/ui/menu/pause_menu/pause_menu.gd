extends Control

signal resume

@onready var resume_btn := $Panel/VBC/Middle/VBC/Resume as Button
@onready var main_menu_btn := $Panel/VBC/Middle/VBC/MainMenu as Button
@onready var anim_player := $Panel/AnimationPlayer as AnimationPlayer


func _ready():
	hide()


func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		accept_event()
		close_pause_menu()


## Stop game and show pause menu
func open_pause_menu():
	get_tree().paused = true
	show()
	anim_player.play("bounce_up")
	resume_btn.grab_focus()


## Start game and hide pause menu
func close_pause_menu():
	get_tree().paused = false
	anim_player.play("bounce_down")


func _on_resume_button_up():
	close_pause_menu()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "bounce_down":
		hide()
		emit_signal("resume")


func _on_main_menu_button_down():
	close_pause_menu()
