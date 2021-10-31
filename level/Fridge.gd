class_name Fridge
extends Area

export var activity_cold_beverage: Resource
export var cold_beverage_scene: PackedScene

enum States {IDLE, WORKING}

var should_ignore_clicks: bool = false
var hovered: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

onready var outline = find_node("Outline", true, false)
onready var tooltip: SpatialLabel = $Togglables/SpatialLabel
onready var cold_beverage = cold_beverage_scene.instance()
onready var game_node = $"/root/Game"

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	connect("mouse_exited", self, "unhover")


func hover() -> void:
	hovered = true


func unhover() -> void:
	hovered = false
	tooltip.hide()
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
		var barista = $"/root/Game".player_visual
		if barista:
			barista.cooling_off_sfx.play()
		eprint("finished chilling at the fridge")
		state = States.IDLE
		return

	# Determine if we should be showing highlight
	if state != States.WORKING and hovered:
		var activity_intent = get_current_activity_intent()
		if activity_intent:
			var current_activity_title = activity_intent["activity"].displayed_name
			tooltip.show_text(current_activity_title)
			if outline:
				outline.show()
		else:
			tooltip.hide()
			if outline:
				outline.hide()
	else:
		tooltip.hide()
		if outline:
			outline.hide()

func set_using():
	should_ignore_clicks = false
	eprint("using the fridge...")
	state = States.WORKING
	var beverage_duration: float = activity_cold_beverage.duration
	timeout = get_node(@"/root/Game").time_elapsed + beverage_duration
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.anim
	$under_counter_fridge_exportPrep/AnimationPlayer.play("ArmatureAction")
	animation_player.play("crouch")
	if !HintPopup.firstfridgeuse:
		HintPopup.firstfridgeuse = true
		HintPopup.display("Consuming a cold refreshing beverage will help you keep your cool, and make the customers slightly more tolerable", 3.0)
	yield(animation_player, "animation_finished")
	var barista = $"/root/Game".player_visual
	barista.carry_attachment.add_child(cold_beverage)
	yield(get_tree().create_timer(0.25), "timeout")
	$under_counter_fridge_exportPrep/AnimationPlayer.play_backwards("ArmatureAction")
	animation_player.play("uncrouch")
	yield(animation_player, "animation_finished")
	var tween = barista.get_node("Tween")
	tween.interpolate_property(barista, "rotation:y", barista.rotation.y, barista.rotation.y + (0.5 * TAU), 0.25)
	tween.start()
	yield(tween, "tween_completed")
	animation_player.play("drinkBeverage")
	yield(animation_player, "animation_finished")
	barista.carry_attachment.remove_child(cold_beverage)

# TODO: convert this into speech baloons
func eprint(text: String):
	print("FRIDGE: %s" % text)
