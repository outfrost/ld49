extends Spatial

#Define locations for the customers to go

onready var _forward_debug_mesh:MeshInstance = $DebugForwardMesh
onready var original_material = $MeshInstance.get_active_material(0).duplicate()

var busy:bool = false
var allocated_by:Spatial = null

export var show_debug:bool = false

func get_focus_direction()->Vector3:
	var forward:Vector3 = global_transform.basis.z
	return forward

func set_busy(value:bool, node:Spatial)->bool:
	if allocated_by != null and node != null:
		if allocated_by != node:
			return false
	busy = value
	allocated_by = node
	update()
	return true

func leave() -> void:
	set_busy(false, null)
	if(self.is_in_group("ask_food_spot")):
		OrderRepository.set_customer_waiting_on_ask_spot(null)

func _ready():
	if not OS.has_feature("debug") or not show_debug:
		hide()
	else:
		_forward_debug_mesh.global_transform.origin = _forward_debug_mesh.global_transform.origin + (get_focus_direction())


func update()->void:
	if OS.has_feature("debug") and show_debug:
		if busy:
			var copy = $MeshInstance.get_active_material(0).duplicate()
			copy.albedo_color = Color(1,0,0)
			$MeshInstance.material_override = copy
		else:
			$MeshInstance.material_override = original_material
