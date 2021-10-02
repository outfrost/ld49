extends Node

#Repository to manage scene changes
#Supposed to be called after fading or effects

enum {main_menu, credits}

var scenes:Dictionary = {
	main_menu:"res://game/menu/MainMenu.tscn",
	credits:"",
}

func change_scene_to(id:int) -> bool:
	if !(id in scenes.keys()):
		printerr("Error, the scene id does not exist")
		return false
	ErrorHandler.handle(get_tree().change_scene_to(scenes[id]))
	return true

