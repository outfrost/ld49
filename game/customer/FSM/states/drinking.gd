extends '../base.gd'


func enter():
	.enter()
	#Will change automatically to leaving after some time
	base_customer.anim_state_machine.travel("customerDrinkIdle")

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return
	base_customer._face_focus_direction()
