class_name EspressoMachine
extends Area

export(OrderRepository.possible_orders) var coffee_type

const start_duration: float = 1.0 # seconds
const cooking_duration: float = 5.0 # seconds
const resetting_duration: float = 0.2 # seconds

var coffee_name: String

var activity_start_machine: Activity
var activity_taking_coffee: Activity

enum States {IDLE, WORKING, READY, RESETTING}

var should_ignore_clicks: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

var cup_empty_node: Spatial
var cup_full_node: Spatial
var ready_light: MeshInstance
var brewing_sound: AudioStreamPlayer3D
var ready_sound: AudioStreamPlayer3D
var outline: Spatial
var brewing_particles: Particles
var brewing_particles2: Particles

onready var tooltip: SpatialLabel = $Togglables/SpatialLabel

func _ready() -> void:
	coffee_name = OrderRepository.get_coffe_name(coffee_type)
	activity_start_machine = Activity.new("Make %s" % coffee_name, start_duration)
	activity_taking_coffee = Activity.new("Take %s" % coffee_name, resetting_duration)
	connect("mouse_entered", self, "hover")
	connect("mouse_exited", self, "unhover")
	cup_empty_node = $Togglables/CupEmpty
	cup_empty_node.visible = false
	cup_full_node = $Togglables/CupFull
	cup_full_node.visible = false
	ready_light = $Togglables/ReadyLight
	ready_light.visible = true
	brewing_sound = $Togglables/BrewingSound
	brewing_sound.playing = false
	brewing_particles = $Model/SteamEmitter/Particles
	brewing_particles2 = $Model/SteamEmitter2/Particles
	self._emitParticles(false)
	ready_sound = $Togglables/ReadySound
	ready_sound.playing = false
	outline = find_node("Outline", true, false)

	# IDEA: derive initial state of the machine based on the togglables' visibility
	pass

func hover() -> void:
	var activity_intent = get_current_activity_intent()
	if !activity_intent:
		return
	var current_activity_title = activity_intent["activity"].displayed_name
	tooltip.show_text(current_activity_title)
	if outline:
		outline.show()
	pass

func unhover() -> void:
	tooltip.hide()
	if outline:
		outline.hide()

func get_current_activity_intent():
	if !$"/root/Game".player_visual.is_emptyhanded():
		return false
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
		brewing_sound.stop()
		ready_sound.play()
		self._emitParticles(false)
		if !HintPopup.firstmachinedone:
			HintPopup.firstmachinedone = true
			HintPopup.display("The coffee machine is done brewing, go grab the drink and place it on the order tray", 5.0)
		return
	if state == States.RESETTING and is_timeout:
		eprint("coffee machine is free!")
		state = States.IDLE
		cup_empty_node.visible = false
		cup_full_node.visible = false
		$"/root/Game".player_visual.take_cup(coffee_type)
		return
	pass

func set_working():
	should_ignore_clicks = false
	eprint("brewing the coffee...")
	state = States.WORKING
	timeout = get_node(@"/root/Game").time_elapsed + cooking_duration
	cup_empty_node.visible = true
	ready_light.visible = false
	brewing_sound.play()
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
	animation_player.play("reachAppliance")
	self._emitParticles(true)
	if !HintPopup.firstmachineuse:
		HintPopup.firstmachineuse = true
		HintPopup.display("Keep in mind, you can queue up multiple machines, even if a customer hasn't ordered yet", 5.0)
		HintPopup.display("Be carefule though, too much time near the machines will make you hot", 5.0)

func set_resetting():
	should_ignore_clicks = false
	if !$"/root/Game".player_visual.is_emptyhanded():
		return false
	# state = States.IDLE
	state = States.RESETTING
	timeout = get_node(@"/root/Game").time_elapsed + resetting_duration
	ready_light.visible = true
	self._emitParticles(false)
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
	animation_player.play("armsCarryStart")

# TODO: convert this into speech baloons
func eprint(text: String):
	print("ESPRESSO: %s" % text)

func _emitParticles(enable:bool):
	brewing_particles.emitting = enable
	brewing_particles2.emitting = enable
