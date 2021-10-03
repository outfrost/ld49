extends Spatial

#Define locations for the customers to go

var busy:bool = false

func set_busy(value:bool)->void:
	busy = value

func leave() -> void:
	busy = false


func _ready():
	if not OS.has_feature("debug"):
		hide()

func update():
	if OS.has_feature("debug"):
		if busy:
			var copy = $MeshInstance.get_active_material(0).duplicate()
			copy.albedo_color = Color(1,0,0)
			$MeshInstance.material_override = copy
		else:
			var copy = $MeshInstance.get_active_material(0).duplicate()
			copy.albedo_color = Color(0,1,0)
			$MeshInstance.material_override = copy
