extends Spatial

#Hide on production, define places for customers to spawn/exit

func _ready():
	if not OS.has_feature("debug"):
		hide()
