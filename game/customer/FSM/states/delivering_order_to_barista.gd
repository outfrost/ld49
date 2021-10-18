extends '../base.gd'

func enter():
	.enter()
	base_customer.anim_state_machine.travel("customerOrdering")
	$Timer.start()

func exit():
	.exit()

func _on_Timer_timeout():
	base_customer.go_waiting_spot()
