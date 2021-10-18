extends '../base.gd'

func enter():
	.enter()

func exit():
	.exit()

func _physics_process(delta):
	if not active:
		return
	if not is_instance_valid(base_customer):
		return
	var generated_order_is_empty = base_customer.customer_generated_food_order.empty()
	var took_order = base_customer.barista_took_order

	if not generated_order_is_empty and not took_order:
		var ask_food_spot:Spatial = base_customer.go_ask_for_food_spot()
		if not is_instance_valid(ask_food_spot):
			#wait on a table, if none available, will wait until finds one
			base_customer.go_waiting_spot()
