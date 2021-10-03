class_name EspressoMachine
extends Area

const cooking_duration: float = 5.0 # seconds
const resetting_duration: float = 1.0 # seconds

var activity_start_machine = Activity.new("Starting a coffee machine")
var activity_taking_coffee = Activity.new("Taking fresh coffee from a coffee machine", resetting_duration)

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
	# TODO: add outline effect to the object
		# NOTE: make sure there is only one object outlined at a time
	pass

func _input_event(camera, event, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT or !event.pressed:
		return
	match state:
		States.IDLE:
			if get_node(@"/root/Game").set_activity(activity_start_machine):
				set_working()
			return
		States.WORKING:
			eprint("the coffee machine is busy can't you see!")
			# make some unhappy machine noises as machine is buy
			continue
		States.READY:
			if get_node(@"/root/Game").set_activity(activity_taking_coffee):
				set_resettin()
			continue
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
func set_resettin():
	# state = States.IDLE
	state = States.RESETTING
	timeout = get_node(@"/root/Game").time_elapsed + resetting_duration
	cup_node.visible = false
	# set machine state to resetting
	# setup a timeout for machine to switch to ready
	
func eprint(text: String):
	print("ESPRESSO: %s" % text)

