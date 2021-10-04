class_name ServingTray
extends Area

export var activity_place_item: Resource

const call_customer_duration = 2.0 # seconds
var activity_call_customer = Activity.new("Call customer for pickup", call_customer_duration)

enum States {IDLE, WORKING}

var should_ignore_clicks: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

var items_container_object: Spatial
var valid_item_locations: Array = []

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	items_container_object = $Items
	var item_locations_container = $ItemLocations
	if item_locations_container:
		for i in item_locations_container.get_children():
			if i is Position3D:
				valid_item_locations.push_back(i)
	pass

func hover() -> void:
	var activity_intent = get_current_activity_intent()
	if !activity_intent:
		return
	var current_activity_title = activity_intent["activity"].displayed_name
	#print("ACTIVITY TITLE: %s" % current_activity_title)
	# TODO: add a tooltip saying current title
	# TODO: add outline effect to the object
		# NOTE: make sure there is only one object outlined at a time
	pass

func get_current_activity_intent():
	# TODO: check if player has anything to put on the tray
	if should_ignore_clicks:
		eprint("was clicked already")
		return false
	var is_barista_empty = $"/root/Game".player_visual.is_emptyhanded()
	if is_barista_empty:
		return {"activity": activity_call_customer, "handler": "call_customer"}
	else:
		return {"activity": activity_place_item, "handler": "set_putting"}

func _input_event(camera, event, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed:
		return
	var activity_intent = get_current_activity_intent()
	if activity_intent:
		should_ignore_clicks = true
		var location = $ActivityLocations/Position3D
		# TODO: have multiple locations to choose from, randomize it

		get_node(@"/root/Game").set_activity(activity_intent["activity"], self, activity_intent["handler"], location)
	match state:
		States.IDLE:
			return
		States.WORKING:
			eprint("using tray already")
			return

func _process(delta: float) -> void:
	var is_timeout = get_node(@"/root/Game").time_elapsed > timeout
	if state == States.WORKING and is_timeout:
		state = States.IDLE
		var new_item = $ItemSamples/Cup.duplicate()
		var player_coffee_type = $"/root/Game".player_visual.remove_cup()
		if player_coffee_type is int:
			new_item.coffee_type = player_coffee_type
			new_item.visible = true
			if !put_item(new_item):
				eprint("failed to put an item")
				return
		else:
			eprint("failed to put an item")
			return
		# TODO: make a "SLAP" noise for putting cup on the tray
		eprint("just put an item on the tray")
		return
	pass

func put_item(item: Spatial) -> bool:
	if !items_container_object:
		return false
	var index = items_container_object.get_child_count()
	if index >= valid_item_locations.size():
		#take_items()
		return false
	var position: Position3D = valid_item_locations[index]
	var origin = position.global_transform.origin
	items_container_object.add_child(item)
	item.global_transform.origin = origin
	return true

func call_customer():
	should_ignore_clicks = false
	if OrderRepository.order_queue.size():
		eprint("calling customer!")
		var customer_to_call = OrderRepository.order_queue.keys()[0]
		OrderRepository.barista_call_client_to_get_food(customer_to_call)
	pass

func take_items():
	if !items_container_object:
		return
	var item_count = items_container_object.get_child_count()
	for i in items_container_object.get_children():
		var item_type = i.coffee_type
		OrderRepository.barista_add_item_to_delivery(item_type)
		items_container_object.remove_child(i)


func set_putting():
	should_ignore_clicks = false
	eprint("putting item...")
	state = States.WORKING
	# TODO: play animation of moving item from hands to tray
	var serve_duration: float = activity_place_item.duration
	timeout = get_node(@"/root/Game").time_elapsed + serve_duration

# TODO: convert this into speech baloons
func eprint(text: String):
	print("TRAY: %s" % text)

