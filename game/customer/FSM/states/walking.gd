extends '../base.gd'

var current_speed:float = 0

export var max_speed:float = 2

var lock_z_axis:bool = false
var locked_height:float = 0

func _ready():
	if lock_z_axis:
		locked_height = base_customer.global_transform.origin.y

func enter():
	.enter()
	base_customer.anim_state_machine.travel("walking")
	base_customer.max_waiting_timer.start()

func exit():
	.exit()
	pass

func _physics_process(delta):
	if not active:
		return

	if base_customer.path_node < base_customer.path.size(): #Must move to reach destination
		var direction:Vector3 = base_customer.path[base_customer.path_node] - base_customer.global_transform.origin
		if direction.length() < 0.1:
			base_customer.path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			base_customer.move_and_slide(direction.normalized() * current_speed, Vector3.UP)
			#Customers can look where they are moving
			base_customer.rotation.y = lerp(base_customer.rotation.y, atan2(direction.x, direction.z), 0.1)

			if lock_z_axis:
				base_customer.global_transform.origin.y = locked_height
	else: ##Reached destination

		#Customer drinking
		if base_customer.got_food:
			FSM.change_state(FSM.drinking)
		###############################################

		#Customer picking up food
		if base_customer.barista_called_for_delivery and not base_customer.got_food: #Stopped walking at the checkout spot
			#TODO: pick up food
			FSM.change_state(FSM.picking_up_beverage)
			return
		###############################################

		#Customer waiting to/for order
		if not base_customer.barista_took_order:
			FSM.change_state(FSM.waiting_to_order)
		else:
			if not base_customer.got_food:
				FSM.change_state(FSM.waiting_for_order)
		###############################################

		#Customer at despawn point
		if base_customer.target and base_customer.target.is_in_group("exit_spot"):
			base_customer.emit_despawning()
			base_customer.call_deferred("queue_free")
		##############################################

		#Customer is at the ask_food_spot
		if base_customer.allocated_spot.is_in_group(base_customer.spots_collection.spot_names[base_customer.spots_collection.ask_food_spot]):
			OrderRepository.set_customer_waiting_on_ask_spot(base_customer)
			if !HintPopup.firstorder:
				HintPopup.firstorder = true
				HintPopup.display("A customer is ready to order, don't make them wait too long", 5.0)
		##############################################
