extends Spatial

#Define locations for the customers to go

onready var original_material = $MeshInstance.get_active_material(0).duplicate()
var busy:bool = false
var allocated_by:Spatial = null

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
	if not OS.has_feature("debug"):
		hide()

func update()->void:
	if OS.has_feature("debug"):
		if busy:
			var copy = $MeshInstance.get_active_material(0).duplicate()
			copy.albedo_color = Color(1,0,0)
			$MeshInstance.material_override = copy
		else:
			$MeshInstance.material_override = original_material
