class_name Fridge
extends Area

export var activity_cold_beverage: Resource

enum States {IDLE, WORKING}

var should_ignore_clicks: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

onready var outline = find_node("Outline", true, false)

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	connect("mouse_exited", self, "unhover")
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
	if outline:
		outline.show()
	pass

func unhover() -> void:
	if outline:
		outline.hide()

func get_current_activity_intent():
	if !$"/root/Game".player_visual.is_emptyhanded():
		return false
	if should_ignore_clicks:
		eprint("was clicked already")
		return false
	return {"activity": activity_cold_beverage, "handler": "set_using"}

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
			eprint("chilling already")
			# make some unhappy machine noises as machine is buy
			return

func _process(delta: float) -> void:
	var is_timeout = get_node(@"/root/Game").time_elapsed > timeout
	if state == States.WORKING and is_timeout:
		eprint("finished chilling at the fridge")
		state = States.IDLE
		var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
		animation_player.play("uncrouch")
		# TODO: make a "fridge closing" noise
		return
	pass

func set_using():
	should_ignore_clicks = false
	eprint("using the fridge...")
	state = States.WORKING
	var beverage_duration: float = activity_cold_beverage.duration
	timeout = get_node(@"/root/Game").time_elapsed + beverage_duration
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
	animation_player.play("crouch")
	if !HintPopup.firstfridgeuse:
		HintPopup.firstfridgeuse = true
		HintPopup.display("Consuming a cold refreshing beverage will help you keep your cool, and make the customers slightly more tolerable", 3.0)
	yield(animation_player, "animation_finished")
	animation_player.play("drink_beverage")

# TODO: convert this into speech baloons
func eprint(text: String):
	print("FRIDGE: %s" % text)
