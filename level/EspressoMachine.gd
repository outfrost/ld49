class_name EspressoMachine
extends Area

const start_duration: float = 1.0 # seconds
const cooking_duration: float = 5.0 # seconds
const resetting_duration: float = 1.0 # seconds

var activity_start_machine = Activity.new("Start a coffee machine", start_duration)
var activity_taking_coffee = Activity.new("Take fresh coffee from a coffee machine", resetting_duration)

enum States {IDLE, WORKING, READY, RESETTING}

var should_ignore_clicks: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

var cup_empty_node: Spatial
var cup_full_node: Spatial
var ready_light: MeshInstance
var brewing_sound: AudioStreamPlayer3D

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	cup_empty_node = $Togglables/CupEmpty
	cup_empty_node.visible = false
	cup_full_node = $Togglables/CupFull
	cup_full_node.visible = false
	ready_light = $Togglables/ReadyLight
	ready_light.visible = true
	brewing_sound = $Togglables/BrewingSound
	brewing_sound.playing = false

	# IDEA: derive initial state of the machine based on the togglables' visibility
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
	if should_ignore_clicks:
		eprint("was clicked already")
		return false
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
		should_ignore_clicks = true
		var location = $ActivityLocations/Position3D
		# TODO: have multiple locations to choose from, randomize it

		get_node(@"/root/Game").set_activity(activity_intent["activity"], self, activity_intent["handler"], location)
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
		eprint("coffee is ready!")
		state = States.READY
		cup_empty_node.visible = false
		cup_full_node.visible = true
		ready_light.visible = true
		brewing_sound.playing = false
		# TODO: make a "ready" noise
		return
	if state == States.RESETTING and is_timeout:
		eprint("coffee machine is free!")
		state = States.IDLE
		cup_empty_node.visible = false
		cup_full_node.visible = false
		# TODO: give player the coffe cup
		return
	pass

func set_working():
	should_ignore_clicks = false
	eprint("brewing the coffee...")
	state = States.WORKING
	timeout = get_node(@"/root/Game").time_elapsed + cooking_duration
	cup_empty_node.visible = true
	ready_light.visible = false
	brewing_sound.playing = true
func set_resetting():
	should_ignore_clicks = false
	# state = States.IDLE
	state = States.RESETTING
	timeout = get_node(@"/root/Game").time_elapsed + resetting_duration
	ready_light.visible = true

# TODO: convert this into speech baloons
func eprint(text: String):
	print("ESPRESSO: %s" % text)

