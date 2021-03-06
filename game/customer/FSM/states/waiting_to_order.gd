extends '../base.gd'

var warning: bool = false

func enter():
	.enter()
	base_customer.anim_state_machine.travel("wait_register")
	base_customer.max_waiting_timer.start()
	warning = false
	base_customer.add_icon(base_customer.possible_icons.wait_chill)
	base_customer._face_focus_direction(base_customer.allocated_spot)
func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return

	if base_customer.barista_took_order:
		FSM.change_state(FSM.waiting_for_order)
		return

	if inverse_lerp(0, base_customer.max_waiting_timer.wait_time, base_customer.max_waiting_timer.time_left) < 0.5 and !warning:
		warning = true
		base_customer.grumble()

	#If the customer is waiting to ask for order, it will wait for the ask_spot to be free
	if is_instance_valid(base_customer.allocated_spot):
		if not base_customer.allocated_spot.is_in_group(base_customer.spots_collection.spot_names[base_customer.spots_collection.ask_food_spot]):
			base_customer.go_ask_for_food_spot()
