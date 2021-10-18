extends Node

func _ready() -> void:
	var tween_controller = $Tween
	tween_controller.repeat = true
	tween_controller.interpolate_property(self, "rotation:y", 0, TAU, 2.0)
	tween_controller.start()
