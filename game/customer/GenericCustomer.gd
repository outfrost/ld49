extends KinematicBody

#Generic Customer script
#Implements path finding, order delivery and mood

var spots_collection = load("res://game/customer/spots/SpotsGroupList.gd").new()


var customer_possible_difficulty = [1, 2, 3] #Difficulty will halve time to please the customer
onready var customer_difficulty = customer_possible_difficulty[randi() % customer_possible_difficulty.size()]

export var waiting_time_tolerance = 100
onready var max_waiting_timer:Timer = $MaxWaitingTime


signal started_walking
signal started_idling
signal despawning(node)

var barista_took_order:bool = false
var barista_called_for_delivery:bool = false
var got_food:bool = false

var target:Spatial = null
var path = []
var path_node = 0
onready var navmesh:Navigation =  get_parent()
onready var FSM:Node = get_node("FSM")

onready var customer_generated_food_order = OrderRepository.generate_order(customer_difficulty, false)

var allocated_spot:Spatial = null

onready var speech_bubble = $SpeechBubble
onready var anim_tree = $AnimationTree
onready var anim_state_machine = anim_tree.get("parameters/playback")
onready var animPlayer:AnimationPlayer = $customer/AnimationPlayer

var order_score = 0

#Animation timers, will make the customer wait before changing state, so the animation has time to play
onready var pickup_food_timer:Timer = $AnimationTimers/PickupFoodTimer
onready var place_order_timer:Timer = $AnimationTimers/PlaceOrderTimer
var pickup_food_order_check:bool = false
var place_order_timer_check:bool = false


func _face_focus_direction(override_for_animation:bool = false)->void:
#TODO: update to new FSM
#	if current_state == states.walking and not override_for_animation:
#		return
	if allocated_spot == null:
		return
	if not allocated_spot.has_method("get_focus_direction"):
		return
	var direction:Vector3 = (allocated_spot.global_transform.origin+allocated_spot.get_focus_direction())-global_transform.origin
	rotation.y = lerp(rotation.y, atan2(direction.x, direction.z), 0.1)

func _get_and_allocate_spot(group_name:String)->Spatial:
	var seats:Array = get_tree().get_nodes_in_group(group_name)
	seats.shuffle()
	for i in seats:
		if not i.busy:
			var attempt = i.set_busy(true, self)
			if attempt:
				if is_instance_valid(allocated_spot) and allocated_spot.has_method("leave"):
					allocated_spot.leave()
				allocated_spot = i
				return i
			else:
				return null
	#Did not find spot
	return null

func call_customer_to_deliver_zone():
	if go_get_food_spot(): #Only true if the spot is allocated by this customer
		barista_called_for_delivery = true

func needs_fullfilled():
	OrderRepository.remove_order(self)
	OrderRepository.emit_signal("client_satisfied", self)

func deliver_order_to_barista()->void:
	FSM.change_state(FSM.delivering_order_to_barista)
	barista_took_order = true
	OrderRepository.add_order(self, customer_generated_food_order)
	speech_bubble.render_orders(customer_generated_food_order)
	speech_bubble.show_bubble()

func receive_order(received_item:int)->bool: #True = the delivered item is correct
	if received_item in customer_generated_food_order:
		customer_generated_food_order.erase(received_item)
		if customer_generated_food_order.empty():
			needs_fullfilled()
			speech_bubble.hide_bubble()
			return true
		speech_bubble.render_orders(customer_generated_food_order)
	return false

func go_ask_for_food_spot()->Spatial:
	if is_instance_valid(allocated_spot) and allocated_spot.is_in_group("ask_food_spot"):
		return allocated_spot
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.ask_food_spot])
	move_to(target)
	return target

func go_waiting_spot()->void:
	if is_instance_valid(allocated_spot):
		if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.waiting_spot]):
			return
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.waiting_spot])
	move_to(target)

func go_get_food_spot()->bool:
	if is_instance_valid(allocated_spot):
		if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.get_food_spot]):
			return true
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.get_food_spot])
	if is_instance_valid(target):
		move_to(target)
		return true
	return false

func find_seat()->void:
	target = _get_and_allocate_spot(spots_collection.spot_names[spots_collection.drinking_spot])
	move_to(target)

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
	animPlayer.get_animation("customerWalk").loop = true
	animPlayer.get_animation("drinkBeverage").loop = true
	animPlayer.get_animation("customerWaitTable").loop = true
	animPlayer.get_animation("customerWaitRegister").loop = true
	animPlayer.get_animation("customerDrinkIdle").loop = true

	max_waiting_timer.wait_time = waiting_time_tolerance/customer_difficulty
	max_waiting_timer.start()

func move_to(target:Spatial):
	if target == null:
		return
	path = navmesh.get_simple_path(global_transform.origin, target.global_transform.origin)
	path_node = 0
	FSM.change_state(FSM.walking)


func _on_MaxWaitingTime_timeout():
	pass
	#TODO: Update to new FSM
#	match current_state:
#		states.waiting_for_order:
#			print("Customer expired, reason: waited for order too long")
#			leave_and_go_away()
#			OrderRepository.emit_signal("client_enraged", self) #Kept waiting forever, not cool
#		states.waiting_to_order:
#			print("Customer expired, reason: waited to order too long")
#			leave_and_go_away()
#			OrderRepository.emit_signal("client_enraged", self) #Not delivered on time, very mad
#		states.drinking:
#			print("Customer expired, reason: consumed drink")
#			if order_score > 50:
#				needs_fullfilled()
#			else:
#				OrderRepository.emit_signal("client_enraged", self)
#			leave_and_go_away()
#		states.idle:
#			print("Customer expired, reason: expired while idling")
#			leave_and_go_away()
#		states.walking:
#			max_waiting_timer.start() #Reset time, was walking, dont go away in this state ever
#		_:
#			printerr("Customer tolerance time expired while he was in a unexpected state", current_state, get_stack())


#After the customer placed the order
func _on_PlaceOrderTimer_timeout():
	go_waiting_spot()
