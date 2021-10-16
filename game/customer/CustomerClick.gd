extends Spatial

var mouse_hovering:bool = false

func _on_AreaUserCustomerInteraction_mouse_entered():
	mouse_hovering = true


func _on_AreaUserCustomerInteraction_mouse_exited():
	mouse_hovering = false

func _on_AreaUserCustomerInteraction_input_event(camera, event:InputEvent, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed or !mouse_hovering:
		return
	OrderRepository.customer_clicked(get_parent())
