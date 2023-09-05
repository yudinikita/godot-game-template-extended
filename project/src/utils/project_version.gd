@tool
class_name ProjectVersion
extends Node


static func get_version() -> String:
	var v = load("res://version.gd")
	return "v{major}.{minor}.{patch}".format(
		{"major": str(v.MAJOR), "minor": str(v.MINOR), "patch": str(v.PATCH)}
	)
