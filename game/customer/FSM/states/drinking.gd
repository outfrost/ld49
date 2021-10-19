extends '../base.gd'


func enter():
	.enter()
	#Will change automatically to leaving after some time
	base_customer.anim_state_machine.travel("customerDrinkIdle")
	base_customer.max_waiting_timer.stop() #Uses the MaxDrinkingTime to adjust the customer drinking time to a different number
	$MaxDrinkingTime.start() #<-------------------
	base_customer._face_focus_direction(base_customer.allocated_spot)

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return

func _on_MaxDrinkingTime_timeout():
	base_customer._on_MaxWaitingTime_timeout()
