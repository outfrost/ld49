extends KinematicBody

#Generic Customer script
#Implements path finding, order delivery and mood

var spots_collection = load("res://game/customer/spots/SpotsGroupList.gd").new()

const TEXTURES: Array = [
	preload("res://art_assets/customer/customerDiffuseA.png"),
	preload("res://art_assets/customer/customerDiffuseB.png"),
	preload("res://art_assets/customer/customerDiffuseC.png"),
]

enum states {idle, waiting_to_order, waiting_for_order, drinking, walking}
enum feelings {happy, indifferent, bored, insane}
enum possible_icons {wait_chill, wait_warning, wait_angry}

var icon_scenes: Dictionary = {
	possible_icons.wait_chill:load("res://assets/Icon_Waiting_Chill.tscn"),
	possible_icons.wait_warning:load("res://assets/Icon_Waiting_Warning.tscn"),
	possible_icons.wait_angry:load("res://assets/Icon_Waiting_Angry.tscn")
}

onready var icon_attachment: Node = $Icon

var current_state:int = states.idle

var customer_possible_difficulty = [1, 2, 3] #Difficulty will halve time to please the customer
onready var customer_difficulty = customer_possible_difficulty[randi() % customer_possible_difficulty.size()]
export var max_speed:float = 10
export var waiting_time_tolerance = 100
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
	if current_state == states.walking and not override_for_animation:
		return
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
	barista_took_order = true
	place_order_timer.start()
	anim_state_machine.travel("customerOrdering")
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

	if lock_z_axis:
		locked_height = global_transform.origin.y
	max_waiting_timer.wait_time = waiting_time_tolerance/customer_difficulty
	max_waiting_timer.start()

	var model: MeshInstance = $customer/customerArmature/Skeleton/customer
	var mat: SpatialMaterial = model.mesh.surface_get_material(0).duplicate()
	mat.albedo_texture = TEXTURES[randi() % TEXTURES.size()]
	model.set_surface_material(0, mat)

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
			#Customers can look where they are moving
			rotation.y = lerp(rotation.y, atan2(direction.x, direction.z), 0.1)
			anim_state_machine.travel("walking")
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
				#Every time the customer walks, the timer is reseted
				max_waiting_timer.start()
				if got_food:
					current_state = states.drinking
				if barista_called_for_delivery and not got_food: #Stopped walking at the checkout spot
					#Play pickup food animation
					remove_icon()
					if not pickup_food_timer.is_stopped():
						_face_focus_direction(true)
						return
					if pickup_food_timer.is_stopped() and not pickup_food_order_check:
						pickup_food_timer.start()
						pickup_food_order_check = true
						anim_state_machine.travel("customerPickup")
						return

					got_food = true
					OrderRepository.client_got_order_from_the_counter()
					order_score = OrderRepository.compare_order(OrderRepository.barista_prepared_order, OrderRepository.get_order(self))
					print("The customer gave a rating to the food: ", order_score)
					OrderRepository.remove_order(self)
					speech_bubble.hide_bubble()
					var will_stay_or_leave = rand_range(100, 105)
					if will_stay_or_leave < 10:
						leave_and_go_away()
						return
					else:
						go_waiting_spot()
						return
				if not barista_took_order:
					current_state = states.waiting_to_order
					add_icon(possible_icons.wait_chill)
				else:
					if not got_food:
						current_state = states.waiting_for_order
				emit_signal("started_idling")
				if target and target.is_in_group("exit_spot"):
					emit_signal("despawning", self)
					call_deferred("queue_free")
				if allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]):
					OrderRepository.set_customer_waiting_on_ask_spot(self)
					if !HintPopup.firstorder:
						HintPopup.firstorder = true
						HintPopup.display("A customer is ready to order, don't make them wait too long", 5.0)
			states.waiting_to_order:
				if barista_took_order:
					current_state = states.waiting_for_order
					remove_icon()
					return
				_face_focus_direction()
				if max_waiting_timer.is_stopped():
					#Barista interaction should change state to waiting_for_order, or the timeout will and the customer will get very angry and go away
					max_waiting_timer.start()
				#If the customer is waiting to ask for order, it will wait for the ask_spot to be free
				if is_instance_valid(allocated_spot):
					if not allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]):
						go_ask_for_food_spot()
					else:
						anim_state_machine.travel("wait_register")
			states.waiting_for_order:
				_face_focus_direction()
				if max_waiting_timer.is_stopped():
					#Restart timer
					max_waiting_timer.start()
				if barista_took_order and allocated_spot.is_in_group(spots_collection.spot_names[spots_collection.ask_food_spot]): #Barista has picked the customer order and he is on the asking spot
					pass
				else: #Customer is waiting for order on a table
					if place_order_timer.is_stopped():
						anim_state_machine.travel("wait_table")

				if inverse_lerp(0, max_waiting_timer.wait_time, max_waiting_timer.time_left) < 0.25:
					add_icon(possible_icons.wait_angry)
				elif inverse_lerp(0, max_waiting_timer.wait_time, max_waiting_timer.time_left) < 0.5:
					add_icon(possible_icons.wait_warning)

			states.drinking:
				anim_state_machine.travel("customerDrinkIdle")
				_face_focus_direction()
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
			if order_score > 50:
				needs_fullfilled()
			else:
				OrderRepository.emit_signal("client_enraged", self)
			leave_and_go_away()
		states.idle:
			print("Customer expired, reason: expired while idling")
			leave_and_go_away()
		states.walking:
			max_waiting_timer.start() #Reset time, was walking, dont go away in this state ever
		_:
			printerr("Customer tolerance time expired while he was in a unexpected state", current_state, get_stack())


#After the customer placed the order
func _on_PlaceOrderTimer_timeout():
	go_waiting_spot()

func add_icon(icon_type:int) -> void:
	# Remove any other icons that are currently displayed above the model
	if icon_attachment.get_child_count() > 0:
		for child in icon_attachment.get_children():
			icon_attachment.remove_child(child)

	var icon_instance = icon_scenes[icon_type].instance()
	icon_attachment.add_child(icon_instance)

func remove_icon() -> void:
	if icon_attachment.get_child_count() > 0:
		for child in icon_attachment.get_children():
			icon_attachment.remove_child(child)
