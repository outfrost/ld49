extends '../base.gd'

var warning: bool
var angry: bool

func enter():
	.enter()
	base_customer.anim_state_machine.travel("wait_table")
	base_customer.max_waiting_timer.start()
	warning = false
	angry = false

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return
	base_customer._face_focus_direction()
	if inverse_lerp(0, base_customer.max_waiting_timer.wait_time, base_customer.max_waiting_timer.time_left) < 0.25 and !angry:
		angry = true
		base_customer.add_icon(base_customer.possible_icons.wait_angry)
		base_customer.grumble()
	elif inverse_lerp(0, base_customer.max_waiting_timer.wait_time, base_customer.max_waiting_timer.time_left) < 0.5 and !warning:
		warning = true
		base_customer.add_icon(base_customer.possible_icons.wait_warning)
		base_customer.grumble()
