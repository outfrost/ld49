extends '../base.gd'


func enter():
	.enter()
	base_customer.anim_state_machine.travel("wait_register")
	base_customer.max_waiting_timer.start()

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return
	if base_customer.barista_took_order:
		FSM.change_state(FSM.waiting_for_order)
		return
	base_customer._face_focus_direction()

	#If the customer is waiting to ask for order, it will wait for the ask_spot to be free
	if is_instance_valid(base_customer.allocated_spot):
		if not base_customer.allocated_spot.is_in_group(base_customer.spots_collection.spot_names[base_customer.spots_collection.ask_food_spot]):
			base_customer.go_ask_for_food_spot()
