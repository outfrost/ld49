class_name EspressoMachine
extends Area

const start_duration: float = 1.0 # seconds
const cooking_duration: float = 5.0 # seconds
const resetting_duration: float = 1.0 # seconds

var activity_start_machine = Activity.new("Start a coffee machine", start_duration)
var activity_taking_coffee = Activity.new("Take fresh coffee from a coffee machine", resetting_duration)

enum States {IDLE, WORKING, READY, RESETTING}


var state: int = States.IDLE
var timeout: float = 0.0

var cup_node: MeshInstance

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	cup_node = $Cup
	cup_node.visible = false
	# we could even derive initial state of the machine basedon the cup visibility
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
	match state:
		States.IDLE:
			return {"activity": activity_start_machine, "handler": "set_working"}
		States.READY:
			return {"activity": activity_taking_coffee, "handler": "set_resetting"}
	return false

func _input_event(camera, event, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed:
		return
	var activity_intent = get_current_activity_intent()
	if activity_intent:
		get_node(@"/root/Game").set_activity(activity_intent["activity"], self, activity_intent["handler"])
	match state:
		States.IDLE:
			return
		States.WORKING:
			eprint("the coffee machine is busy can't you see!")
			# make some unhappy machine noises as machine is buy
			continue
		States.READY:
			return
		States.RESETTING:
			# player should be blocked by activity of taking the cup
			continue

func _process(delta: float) -> void:
	var is_timeout = get_node(@"/root/Game").time_elapsed > timeout
	if state == States.WORKING and is_timeout:
		# TODO: make a "ready" noise
		# reset indicators in there are any
		eprint("coffee is ready!")
		state = States.READY
		return
	if state == States.RESETTING and is_timeout:
		eprint("coffee machine is free!")
		state = States.IDLE
		return
	pass

func set_working():
	eprint("brewing the coffee...")
	state = States.WORKING
	timeout = get_node(@"/root/Game").time_elapsed + cooking_duration
	cup_node.visible = true
	# TODO: add a visual indicator to mark the machien working
func set_resetting():
	# state = States.IDLE
	state = States.RESETTING
	timeout = get_node(@"/root/Game").time_elapsed + resetting_duration
	cup_node.visible = false
	# set machine state to resetting
	# setup a timeout for machine to switch to ready

# TODO: convert this into speech baloons
func eprint(text: String):
	print("ESPRESSO: %s" % text)

