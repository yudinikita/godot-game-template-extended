class_name SceneManagerUtils
extends Node

const COLOR: String = "color"
const SHADER_PATTERNS_PATH: String = "res://addons/scene_manager/assets/shader_patterns/"


## Set the color if a timeout exists
static func timeout(timeout: float, animation_player: AnimationPlayer) -> bool:
	if timeout != 0:
		animation_player.play(COLOR, -1, 1, false)
		return true
	return false


## Get patterns from `addons/scene_manager/shader_patterns`
static func get_patterns(patterns: Dictionary) -> void:
	var root_path: String = SHADER_PATTERNS_PATH
	var dir := DirAccess.open(root_path)
	if dir:
		dir.list_dir_begin()

		while true:
			var file_folder: String = dir.get_next()
			if file_folder == "":
				break
			elif file_folder.ends_with(".import"):
				file_folder = file_folder.replace(".import", "")
			if file_folder.ends_with(".png"):
				var key = file_folder.replace("." + file_folder.get_extension(), "")
				if key not in patterns.keys():
					patterns[key] = load(root_path + file_folder)

		dir.list_dir_end()


## Get the key of the scene from its path
static func find_scene_key(path: String) -> String:
	var found_key: String = ""
	for key in Scenes.scenes:
		if key.begins_with("_"):
			continue
		if Scenes.scenes[key]["value"] == path:
			found_key = key
	return found_key


## Get the path of the scene in project
static func get_path_scene(scene) -> String:
	var path: String = ""
	if scene is PackedScene or scene is Node:
		path = scene.resource_path
	elif scene is String:
		path = Scenes.scenes[scene]["value"]
	return path


## Get the node of the last open scene
static func get_last_open_scene(scene_tree: SceneTree) -> Node:
	var root = scene_tree.get_root()
	var last_id = root.get_child_count() - 1
	return root.get_child(last_id)
