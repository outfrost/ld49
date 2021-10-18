extends '../base.gd'

func enter():
	.enter()
	base_customer.anim_state_machine.travel("wait_table")
	base_customer.max_waiting_timer.start()

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return
	base_customer._face_focus_direction()
	if inverse_lerp(0, base_customer.max_waiting_timer.wait_time, base_customer.max_waiting_timer.time_left) < 0.25:
		base_customer.add_icon(base_customer.possible_icons.wait_angry)
	elif inverse_lerp(0, base_customer.max_waiting_timer.wait_time, base_customer.max_waiting_timer.time_left) < 0.5:
		base_customer.add_icon(base_customer.possible_icons.wait_warning)
