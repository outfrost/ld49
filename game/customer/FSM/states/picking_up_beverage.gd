extends '../base.gd'

export (float, 0, 100) var customer_stay_chance:float = 30

func enter():
	.enter()
	base_customer.anim_state_machine.travel("customerPickup")
	base_customer.remove_icon()
	$Timer.start()
	base_customer._face_focus_direction(base_customer.allocated_spot)

	base_customer.order_score = OrderRepository.compare_order(
		OrderRepository.barista_prepared_order,
		OrderRepository.get_order(base_customer))

	if base_customer.order_score >= 50:
		base_customer.happy_sfx.play()
	else:
		base_customer.sad_sfx.play()

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return

func _on_Timer_timeout():
	base_customer.got_food = true
	OrderRepository.client_got_order_from_the_counter()
	OrderRepository.client_gave_review(base_customer.order_score)
	OrderRepository.remove_order(base_customer)
	base_customer.speech_bubble.hide_bubble()

	#This will decide if the customer will be satisfied or not
	if base_customer.order_score >= 50:
		base_customer.needs_fullfilled()
	else:
		base_customer.needs_failed()

	var will_stay_or_leave = rand_range(0, 100)
	if will_stay_or_leave < customer_stay_chance:
		base_customer.leave_and_go_away()
	else:
		#There the customer will timeout at the drinking state
		base_customer.go_waiting_spot()
