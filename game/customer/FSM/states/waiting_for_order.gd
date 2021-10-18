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
