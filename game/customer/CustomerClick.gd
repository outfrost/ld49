extends Spatial

var mouse_hovering:bool = false
onready var base_customer:GenericCustomer = get_parent()
onready var FSM:FiniteStateMachine = base_customer.get_node("FSM")

func _on_AreaUserCustomerInteraction_mouse_entered():
	mouse_hovering = true

func _on_AreaUserCustomerInteraction_mouse_exited():
	mouse_hovering = false

func _on_AreaUserCustomerInteraction_input_event(camera, event:InputEvent, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed or !mouse_hovering:
		return

	#The customer should only be called if he is waiting for some delivery
	match FSM.current_state:
		FSM.waiting_for_order:
			OrderRepository.customer_clicked(base_customer)
		_:
			return
