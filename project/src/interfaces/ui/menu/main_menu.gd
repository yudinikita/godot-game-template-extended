extends Control

@onready var title := $Title as Label
@onready var version := $Version as Label
@onready var project_version := preload("res://version.gd")


func _ready():
	title.text = ProjectSettings.get_setting("application/config/name")
	version.text = ProjectVersion.get_version()
