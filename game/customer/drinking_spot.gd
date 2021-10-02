extends Spatial

#Define locations for the customers to go

var busy:bool = false

func leave() -> void:
	busy = false


func _ready():
	if OS.has_feature("debug"):
		hide()

func _process(delta):
	if OS.has_feature("debug"):
		if busy:
			$MeshInstance.get_active_material(0).albedo_color = Color(1,0,0)
