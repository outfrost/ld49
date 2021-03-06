class_name CustomerClick
extends Spatial

var _mouse_hovering:bool setget set_mouse_hovering, get_mouse_hovering
onready var _base_customer:GenericCustomer = get_parent()
onready var _FSM:FiniteStateMachine = _base_customer.get_node("FSM")
onready var _selection_mesh = $CustomerSelectionView

func call_customer_condition()->bool:
	return not OrderRepository.is_serving_tray_empty() and _FSM.current_state == _FSM.waiting_for_order
#To auxiliate the outline implementation, the mouse_hovering will only be true if all conditions for the customer to be called by the barista are met
func set_mouse_hovering(value:bool)->void:
	_mouse_hovering = value

func get_mouse_hovering()->bool:
	return _mouse_hovering

func _on_AreaUserCustomerInteraction_mouse_entered():
	set_mouse_hovering(true)

func _on_AreaUserCustomerInteraction_mouse_exited():
	set_mouse_hovering(false)

func _on_AreaUserCustomerInteraction_input_event(camera, event:InputEvent, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed or !_mouse_hovering or !call_customer_condition():
		return

	#The customer should only be called if he is waiting for some delivery
	match _FSM.current_state:
		_FSM.waiting_for_order:
			OrderRepository.customer_clicked(_base_customer)
		_:
			return

#Update hovering mesh every frame so the hovering ring can disappear once something can't be clicked
func _process(delta):
	if call_customer_condition() and _mouse_hovering:
		_selection_mesh.show()
	else:
		_selection_mesh.hide()
