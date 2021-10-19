extends '../base.gd'


func enter():
	.enter()
	base_customer.anim_state_machine.travel("customerPickup")
	base_customer.remove_icon()
	$Timer.start()
	base_customer._face_focus_direction(base_customer.allocated_spot)

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return

func _on_Timer_timeout():
	base_customer.got_food = true
	OrderRepository.client_got_order_from_the_counter()
	base_customer.order_score = OrderRepository.compare_order(OrderRepository.barista_prepared_order, OrderRepository.get_order(base_customer))
	print("The customer gave a rating to the food: ", base_customer.order_score)
	OrderRepository.remove_order(base_customer)
	base_customer.speech_bubble.hide_bubble()
	var will_stay_or_leave = rand_range(100, 105)
	if will_stay_or_leave < 10:
		base_customer.leave_and_go_away()
		return
	else:
		base_customer.go_waiting_spot()
		return
