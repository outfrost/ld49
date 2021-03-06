class_name GenericCustomer
extends KinematicBody

#Generic Customer script

var model_modifier:Array

onready var spots_collection:SpotsGroupList = load("res://game/customer/spots/SpotsGroupList.gd").new()

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

export(float, 0.0, 3.0) var grumble_min_pitch: float = 1.0
export(float, 0.0, 3.0) var grumble_max_pitch: float = 1.2

onready var max_waiting_timer:Timer = $MaxWaitingTime


signal started_walking
signal started_idling
signal despawning(node)
signal new_movement_target(target)

var barista_took_order:bool = false
var barista_called_for_delivery:bool = false
var got_food:bool = false

var target:Spatial = null

onready var FSM:FiniteStateMachine = $FSM

onready var customer_generated_food_order = OrderRepository.generate_order(customer_difficulty, false)

var allocated_spot:Spatial = null

onready var speech_bubble = $SpeechBubble
onready var anim_tree = $AnimationTree
onready var anim_state_machine = anim_tree.get("parameters/playback")
onready var animPlayer:AnimationPlayer = $customer/AnimationPlayer
onready var model: MeshInstance = $customer/customerArmature/Skeleton/customer

var order_score = 0

#Animation timers, will make the customer wait before changing state, so the animation has time to play
onready var pickup_food_timer:Timer = $AnimationTimers/PickupFoodTimer
onready var place_order_timer:Timer = $AnimationTimers/PlaceOrderTimer
var pickup_food_order_check:bool = false
var place_order_timer_check:bool = false

var current_focus:Spatial = null
onready var focus_tween:Tween = $FocusTween

onready var waiting_time_sfx: AudioStreamPlayer3D = $WaitingTimeSfx
onready var happy_sfx: AudioStreamPlayer3D = $HappySfx
onready var sad_sfx: AudioStreamPlayer3D = $SadSfx

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func emit_started_walking()->void:
	emit_signal("started_walking")

func emit_started_idling()->void:
	emit_signal("started_idling")

func emit_despawning()->void:
	emit_signal("despawning", self)

func _face_focus_direction(new_focus:Spatial, override_for_animation:bool = false)->void:
	if new_focus == current_focus:
		return
	if FSM.current_state == FSM.walking and not override_for_animation:
		return
	if not is_instance_valid(allocated_spot):
		return
	if not allocated_spot.has_method("get_focus_direction"):
		return
	var direction:Vector3 = (allocated_spot.global_transform.origin+allocated_spot.get_focus_direction())-global_transform.origin
	focus_tween.interpolate_property(self, "rotation",
		rotation, Vector3(rotation.x,atan2(direction.x, direction.z),rotation.z), 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	focus_tween.start()

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
	waiting_time_sfx.pitch_scale = rng.randf_range(grumble_min_pitch, grumble_max_pitch)
	waiting_time_sfx.play()
	OrderRepository.emit_client_is_unhappy(self, grumble_effect * effect_multiplier) #Customer is grumbly

func needs_failed()->void:
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
	add_child(spots_collection)
	animPlayer.get_animation("customerWalk").loop = true
	animPlayer.get_animation("customerWaitTable").loop = true
	animPlayer.get_animation("customerWaitRegister").loop = true
	animPlayer.get_animation("customerDrinkIdle").loop = true

	max_waiting_timer.wait_time = waiting_time_tolerance/customer_difficulty
	max_waiting_timer.start()

	# Clone the mesh to prevent artifacts from shape keys
	var mesh: Mesh = model.mesh.duplicate()
	model.mesh = mesh
	# Clone the material to prevent overwriting source albedo
	var mat: SpatialMaterial = mesh.surface_get_material(0).duplicate()
	mat.albedo_texture = TEXTURES[randi() % TEXTURES.size()]
	model.set_surface_material(0, mat)

	model_modifier = [randf(), randf(), randf()]
	model.set("blend_shapes/bodyThicker", model_modifier[0])
	model.set("blend_shapes/hairRound", model_modifier[1])
	model.set("blend_shapes/hairSharp", model_modifier[2])

func _process(delta) -> void:

	# Check to make sure our shape keys are not randomly changing
	assert(model.get("blend_shapes/moodBad") == 0, "%s - Customer model blend_shapes/moodBad should be 0, current value is %f" % [name, model.get("blend_shapes/moodBad")])
	assert(model.get("blend_shapes/moodGood") == 0, "%s - Customer model blend_shapes/moodGood should be 0, current value is %f" % [name,model.get("blend_shapes/moodGood")])
	assert(model.get("blend_shapes/bodyThicker") == model_modifier[0], "%s - Customer model blend_shapes/bodyThicker should be %f, curret value is %f" % [name, model_modifier[0], model.get("blend_shapes/bodyThicker")])
	assert(model.get("blend_shapes/hairRound") == model_modifier[1], "%s - Customer model blend_shapes/hairRound should be %f, current value is %f" % [name, model_modifier[1],model.get("blend_shapes/hairRound")])
	assert(model.get("blend_shapes/hairSharp") == model_modifier[2], "%s - Customer model blend_shapes/hairSharp should be %f, current value is %f" % [name, model_modifier[2], model.get("blend_shapes/hairSharp")])

func move_to(target:Spatial):
	if target == null:
		return
	emit_signal("new_movement_target", target)
	FSM.change_state(FSM.walking)


func _on_MaxWaitingTime_timeout():
	match FSM.current_state:
		FSM.waiting_for_order:
			print_debug("Customer expired, reason: waited for order too long")
			needs_failed()
			leave_and_go_away()
		FSM.waiting_to_order:
			print_debug("Customer expired, reason: waited to order too long")
			needs_failed()
			leave_and_go_away()
		FSM.drinking:
			print_debug("Customer expired, reason: consumed drink: ", order_score)
			leave_and_go_away()
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
				child.queue_free()

		var icon_instance = icon_scenes[icon_type].instance()
		icon_attachment.add_child(icon_instance)
		set_displayed_icon(icon_type)

func remove_icon() -> void:
	if icon_attachment.get_child_count() > 0:
		for child in icon_attachment.get_children():
			child.queue_free()

		set_displayed_icon(-1)

func set_displayed_icon(icon_type:int):
	displayed_icon = icon_type
