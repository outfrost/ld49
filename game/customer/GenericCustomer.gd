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
onready var displayed_icon: int = -1

var current_state:int = states.idle

var customer_possible_difficulty = [1, 2, 3] #Difficulty will halve time to please the customer
onready var customer_difficulty = customer_possible_difficulty[randi() % customer_possible_difficulty.size()]
onready var effect_multiplier = 0.5 + 0.5 * customer_difficulty
export var max_speed:float = 10
export var waiting_time_tolerance = 100

export var happy_effect: float = 5
export var grumble_effect: float = -1
export var angry_effect: float = -5

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

func emit_started_walking()->void:
	emit_signal("started_walking")

func emit_started_idling()->void:
	emit_signal("started_idling")

func emit_despawning()->void:
	emit_signal("despawning", self)

func _face_focus_direction(override_for_animation:bool = false)->void:
	if FSM.current_state == FSM.walking and not override_for_animation:
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

func call_customer_to_deliver_zone()->bool:
	if go_get_food_spot(): #Only true if the spot is allocated by this customer
		barista_called_for_delivery = true
		return true
	return false

func needs_fullfilled()->void:
	OrderRepository.remove_order(self)
	OrderRepository.emit_client_is_satisfied(self, happy_effect * effect_multiplier)

func grumble()->void:
	OrderRepository.emit_client_is_unhappy(self, grumble_effect * effect_multiplier) #Customer is grumbly

func needs_failed()->void:
	leave_and_go_away()
	OrderRepository.emit_client_is_enraged(self, angry_effect * effect_multiplier) #Kept waiting forever, not cool

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

func _ready():
	animPlayer.get_animation("customerWalk").loop = true
	animPlayer.get_animation("drinkBeverage").loop = true
	animPlayer.get_animation("customerWaitTable").loop = true
	animPlayer.get_animation("customerWaitRegister").loop = true
	animPlayer.get_animation("customerDrinkIdle").loop = true

	max_waiting_timer.wait_time = waiting_time_tolerance/customer_difficulty
	max_waiting_timer.start()
	var model: MeshInstance = $customer/customerArmature/Skeleton/customer
	# Clone the mesh to prevent artifacts from shape keys
	var mesh: Mesh = model.mesh.duplicate()
	model.mesh = mesh
	# Clone the material to prevent overwriting source albedo
	var mat: SpatialMaterial = mesh.surface_get_material(0).duplicate()
	mat.albedo_texture = TEXTURES[randi() % TEXTURES.size()]
	model.set_surface_material(0, mat)

	model.set("blend_shapes/bodyThicker", randf())
	model.set("blend_shapes/hairRound", randf())
	model.set("blend_shapes/hairSharp", randf())

func move_to(target:Spatial):
	if target == null:
		return
	path = navmesh.get_simple_path(global_transform.origin, target.global_transform.origin)
	path_node = 0
	FSM.change_state(FSM.walking)


func _on_MaxWaitingTime_timeout():
	match FSM.current_state:
		FSM.waiting_for_order:
			print_debug("Customer expired, reason: waited for order too long")
			needs_failed()
		FSM.waiting_to_order:
			print_debug("Customer expired, reason: waited to order too long")
			needs_failed()
		FSM.drinking:
			#This will decide if the customer will be satisfied or not
			#The order_score is computed on picking_up_bewerage.gd
			if order_score > 50:
				needs_fullfilled()
				leave_and_go_away()
			else:
				needs_failed()
			print_debug("Customer expired, reason: consumed drink: ", order_score)
		FSM.idle:
			print_debug("Customer expired, reason: expired while idling")
			leave_and_go_away()
		FSM.walking:
			max_waiting_timer.start() #Reset time, was walking, dont go away in this state ever
		_:
			printerr("Customer tolerance time expired while he was in a unexpected state", FSM.current_state, get_stack())

#After the customer placed the order
func _on_PlaceOrderTimer_timeout():
	go_waiting_spot()

func add_icon(icon_type:int) -> void:
	# Remove any other icons that are currently displayed above the model
	if icon_type != displayed_icon:
		if icon_attachment.get_child_count() > 0:
			for child in icon_attachment.get_children():
				icon_attachment.remove_child(child)

		var icon_instance = icon_scenes[icon_type].instance()
		icon_attachment.add_child(icon_instance)
		set_displayed_icon(icon_type)

func remove_icon() -> void:
	if icon_attachment.get_child_count() > 0:
		for child in icon_attachment.get_children():
			icon_attachment.remove_child(child)

		set_displayed_icon(-1)

func set_displayed_icon(icon_type:int):
	displayed_icon = icon_type
