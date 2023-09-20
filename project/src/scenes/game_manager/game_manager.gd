class_name GameManager
extends Node

signal toggle_game_pause(is_paused: bool)

@onready var pause_menu := $CanvasLayer/UI/PauseMenu as Control


func _input(event):
	if event.is_action_pressed("ui_cancel") and !pause_menu.visible:
		pause_menu.open_pause_menu()


func _on_pause_button_up():
	pause_menu.open_pause_menu()
