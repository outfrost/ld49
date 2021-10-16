extends Spatial

#Hide on production, define places for customers to spawn/exit
export var show_debug:bool = false

func _ready():
	if not OS.has_feature("debug") or not show_debug:
		hide()
