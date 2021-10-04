class_name Register
extends Area

export var activity_taking_order: Resource

enum States {IDLE, WORKING}

var should_ignore_clicks: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	pass

func hover() -> void:
	var activity_intent = get_current_activity_intent()
	if !activity_intent:
		return
	var current_activity_title = activity_intent["activity"].displayed_name
	print("Click to %s" % current_activity_title)
	# TODO: add a tooltip saying current title
	# TODO: add outline effect to the object
		# NOTE: make sure there is only one object outlined at a time
	pass

func get_current_activity_intent():
	if should_ignore_clicks:
		eprint("was clicked already")
		return false
	var is_customer_missing: bool = !OrderRepository.customer_waiting_on_ask_spot
	if is_customer_missing:
		return false
	return {"activity": activity_taking_order, "handler": "set_using"}

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
			eprint("accepting order already")
			# make some unhappy machine noises as machine is buy
			return

func _process(delta: float) -> void:
	var is_timeout = get_node(@"/root/Game").time_elapsed > timeout
	if state == States.WORKING and is_timeout:
		eprint("accepted client order")
		state = States.IDLE
		# TODO: make a "fridge closing" noise
		return
	pass

func set_using():
	should_ignore_clicks = false
	eprint("using the register...")
	state = States.WORKING
	# NOTE: it seems this can sometimes return false (failed to take order)
	OrderRepository.take_order_from_customer()
	var order_duration: float = activity_taking_order.duration
	timeout = get_node(@"/root/Game").time_elapsed + order_duration
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
	animation_player.play("reachAppliance")

# TODO: convert this into speech baloons
func eprint(text: String):
	print("REGISTER: %s" % text)

