@tool
extends EditorPlugin

const SETTINGS_PROPERTY_NAME := "scene_manager/scenes/scenes_path"
const DEFAULT_PATH_TO_SCENES := "res://addons/scene_manager/scenes/scenes.gd"
const SCENE_MANAGER_PATH := "res://addons/scene_manager/src/core/scene_manager.tscn"
const MENU_PATH := "res://addons/scene_manager/src/ui/menu/menu.tscn"

var menu: Node


# Plugin installation
func _enter_tree():
	set_properties_for_setting()

	var path_to_scenes = ProjectSettings.get_setting(SETTINGS_PROPERTY_NAME, DEFAULT_PATH_TO_SCENES)
	add_autoload_singleton("SceneManager", SCENE_MANAGER_PATH)
	add_autoload_singleton("Scenes", path_to_scenes)

	menu = preload(MENU_PATH).instantiate()
	menu.name = "Scene Manager"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, menu)


# Plugin uninstallation
func _exit_tree():
	# TODO: We can use this function but it removes the saved value of it
	# along side with the gui setting, if you want to actually just
	# restart the plugin, you have to set the value for scenes path again
	#
	# So... not a good idea to use this:
	#
	# ProjectSettings.clear(SETTINGS_PROPERTY_NAME)
	#
	# We just don't remove the settings for now
	remove_autoload_singleton("SceneManager")
	remove_autoload_singleton("Scenes")
	remove_control_from_docks(menu)
	menu.queue_free()


func set_properties_for_setting():
	if !ProjectSettings.has_setting(SETTINGS_PROPERTY_NAME):
		var property_info = {
			"name": SETTINGS_PROPERTY_NAME,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "scenes.gd"
		}
		ProjectSettings.add_property_info(property_info)

		ProjectSettings.set_initial_value(SETTINGS_PROPERTY_NAME, DEFAULT_PATH_TO_SCENES)
		ProjectSettings.set_as_basic(SETTINGS_PROPERTY_NAME, true)

		# Restart is required as path to Scenes singleton has changed
		ProjectSettings.set_restart_if_changed(SETTINGS_PROPERTY_NAME, true)

		ProjectSettings.save()
