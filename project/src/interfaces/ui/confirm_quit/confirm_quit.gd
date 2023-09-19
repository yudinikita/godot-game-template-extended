extends Control

signal canceled
signal confirmed

@onready var cancel := $Panel/VBC/Bottom/HBC/Cancel as Button
@onready var anim_player := $Panel/AnimationPlayer as AnimationPlayer


func _on_cancel_button_up():
	anim_player.play("bounce_down")


func _on_confirm_button_up():
	emit_signal("confirmed")


func _on_visibility_changed():
	if visible:
		anim_player.play("bounce_up")
		cancel.grab_focus()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "bounce_down":
		emit_signal("canceled")
