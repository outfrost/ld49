extends KinematicBody

#Generic Customer script
#Implements path finding, order delivery and mood

var spots_collection = load("res://game/customer/spots/SpotsGroupList.gd").new()

enum states {idle, waiting_to_order, waiting_for_order, drinking, walking}
enum feelings {happy, indifferent, bored, insane}

var current_state:int = states.idle

var customer_possible_difficulty = [1, 2, 3, 4] #Difficulty will halve time to please the customer
onready var customer_difficulty = customer_possible_difficulty[randi() % customer_possible_difficulty.size()]
export var max_speed:float = 10
export var waiting_for_order_time_tolerance = 60
export var waiting_to_order_time_tolerance = 60
export var consuming_food_time = 60
onready var max_waiting_timer:Timer = $MaxWaitingTime

var current_speed:float = 0
var target:Spatial = null

var path = []
var path_node = 0
onready var navmesh:Navigation = get_parent()

var locked_height:float = 0

signal started_walking
signal started_idling
signal despawning(node)

var barista_took_order:bool = false
var barista_called_for_delivery:bool = false
var got_food:bool = false

#Maybe for some reason the characters are supposed to be locked on the y axis, so they don't climb stuff, not that they will or should
#I'm not sure if they would climb stairs by default
var lock_z_axis:bool = false

onready var customer_generated_food_order = OrderRepository.generate_order(customer_difficulty, false)

var allocated_spot:Spatial = null

func _get_and_allocate_spot(group_name:String)->Spatial:
	var seats:Array = get_tree().get_nodes_in_group(group_name)
	seats.shuffle()
	for i in seats:
		if not i.busy:
			var attempt = i.set_busy(true, self)
			if attempt:
				if allocated_spot != null and allocated_spot.has_method("leave"):
					allocated_spot.leave()
				allocated_spot = i
				return i
			else:
				return null
	#Did not find spot
	return null

func call_customer_to_deliver_zone():
	barista_called_for_delivery = true
	go_get_food_spot()

func needs_fullfilled():
	OrderRepository.remove_order(self)
	OrderRepository.emit_signal("client_satisfied", self)

func deliver_order_to_barista()->void:
	barista_took_order = true
	go_waiting_spot()
	OrderRepository.add_order(self, customer_generated_food_order)

func receive_order(received_item:int)->bool: #True = the delivered item is correct
	if received_item in customer_generated_food_order:
		customer_generated_food_order.erase(received_item)
		if customer_generated_food_order.empty():
			needs_fullfilled()
		return true
	return false

func go_ask_for_food_spot()->Spatial:
	if allocated_spot != null and allocated_spot.is_in_group("ask_food_spot"):
		return allocated_spot
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.ask_food_spot])
	move_to(target)
	return target

func go_waiting_spot()->void:
	if allocated_spot != null:
		if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.waiting_spot]):
			return
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.waiting_spot])
	move_to(target)

func go_get_food_spot()->void:
	if allocated_spot != null:
		if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.get_food_spot]):
			return
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.get_food_spot])
	move_to(target)

func find_seat()->void:
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.drinking_spot])
	move_to(target)

#TODO: wait on counter to deliver order
#TODO: after, go wait somewhere else
#TODO: the barista can call the customer to deliver bewerage

func leave_and_go_away()->void:
	if allocated_spot != null:
		if allocated_spot.has_method("leave"):
			allocated_spot.leave() #current allocated seat

	var exit_spots:Array = get_tree().get_nodes_in_group(spots_collection.spot_names[spots_collection.exit_spot])
	var chosen_exit:Spatial = exit_spots[randi() % exit_spots.size()]
	target = chosen_exit
	allocated_spot = chosen_exit
	move_to(target)
	OrderRepository.remove_order(self)

# Called when the node enters the scene tree for the first time.
func _ready():
	if lock_z_axis:
		locked_height = global_transform.origin.y
	max_waiting_timer.wait_time = max_waiting_timer.wait_time/customer_difficulty
	max_waiting_timer.start()

func _physics_process(delta):
	if path_node < path.size(): #Must move to reach destination
		if current_state != states.walking:
			current_state = states.walking
			emit_signal("started_walking")
		var direction:Vector3 = path[path_node] - global_transform.origin
		if direction.length() < 0.1:
			path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			move_and_slide(direction.normalized() * current_speed, Vector3.UP)
			if lock_z_axis:
				global_transform.origin.y = locked_height
	else: #Reached destination
		match current_state:
			states.idle:
				if not customer_generated_food_order.empty() and not barista_took_order:
					var ask_food_spot = go_ask_for_food_spot()
					if ask_food_spot == null:
						#wait on a table, if none available, will wait until finds one
						go_waiting_spot()
			states.walking:
				if got_food:
					current_state = states.drinking
				if barista_called_for_delivery and not got_food: #Stopped walking at the checkout spot
					got_food = true
					var score = OrderRepository.compare_order(OrderRepository.barista_prepared_order, OrderRepository.get_order(self))
					print("The customer gave a rating to the food: ", score)
					OrderRepository.remove_order(self)
					var will_stay_or_leave = rand_range(100, 105)
					if will_stay_or_leave < 10:
						leave_and_go_away()
						return
					else:
						go_waiting_spot()
						return

				if not barista_took_order:
					current_state = states.waiting_to_order
				else:
					if not got_food:
						current_state = states.waiting_for_order
				emit_signal("started_idling")
				if target and target.is_in_group("exit_spot"):
					emit_signal("despawning", self)
					call_deferred("queue_free")
				if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]):
					OrderRepository.set_customer_waiting_on_ask_spot(self)
			states.waiting_to_order:
				if max_waiting_timer.is_stopped():
					#Barista interaction should change state to waiting_for_order, or the timeout will and the customer will get very angry and go away
					max_waiting_timer.start()
				#If the customer is waiting to ask for order, it will wait for the ask_spot to be free
				if allocated_spot != null:
					if not allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]):
						go_ask_for_food_spot()
			states.waiting_for_order:
				if max_waiting_timer.is_stopped():
					#Restart timer
					max_waiting_timer.start()
				if barista_took_order and allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]): #Barista has picked the customer order and he is on the asking spot
					#Move to some table
					var waiting_spot = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.waiting_spot])
					target = waiting_spot
			states.drinking:
				#Will change automatically to leaving after some time
				pass
			_:
				current_state = states.idle

func move_to(target:Spatial):
	if target == null:
		return
	path = navmesh.get_simple_path(global_transform.origin, target.global_transform.origin)
	path_node = 0


func _on_MaxWaitingTime_timeout():
	match current_state:
		states.waiting_for_order:
			print("Customer expired, reason: waited for order too long")
			leave_and_go_away()
			OrderRepository.emit_signal("client_enraged", self) #Kept waiting forever, not cool
		states.waiting_to_order:
			print("Customer expired, reason: waited to order too long")
			leave_and_go_away()
			OrderRepository.emit_signal("client_enraged", self) #Not delivered on time, very mad
		states.drinking:
			print("Customer expired, reason: consumed drink")
			needs_fullfilled()
			leave_and_go_away()
		states.idle:
			print("Customer expired, reason: expired while idling")
			leave_and_go_away()
		states.walking:
			print("Customer expired, reason: expired while walking")
			leave_and_go_away()
		_:
			printerr("Customer tolerance time expired while he was in a unexpected state", current_state, get_stack())
