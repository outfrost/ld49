class_name ServingTray
extends Area

export var activity_place_item: Resource

enum States {IDLE, WORKING}

var should_ignore_clicks: bool = false
var hovered: bool = false

var state: int = States.IDLE
var timeout: float = 0.0

var items_container_object: Spatial
var valid_item_locations: Array = []

onready var outline = find_node("Outline", true, false)
onready var tooltip: SpatialLabel = $Togglables/SpatialLabel

func _ready() -> void:
	OrderRepository.connect("client_got_order_from_counter", self, "take_items")
	OrderRepository.set_serving_tray(self)
	connect("mouse_entered", self, "hover")
	connect("mouse_exited", self, "unhover")
	items_container_object = $Items
	var item_locations_container = $ItemLocations
	if item_locations_container:
		for i in item_locations_container.get_children():
			if i is Position3D:
				valid_item_locations.push_back(i)
	pass

func hover() -> void:
	hovered = true

func unhover() -> void:
	hovered = false

func get_current_activity_intent():
	# TODO: check if player has anything to put on the tray
	if should_ignore_clicks:
		eprint("was clicked already")
		return null
	if !$"/root/Game".player_visual.is_emptyhanded():
		return {"activity": activity_place_item, "handler": "set_putting"}
	return null

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
			if !HintPopup.firstorderontray:
				HintPopup.firstorderontray = true
				HintPopup.display("Now that the order is on the tray, click the customer to call them to pick it up.", 6.0)
			if !put_item(new_item):
				eprint("failed to put an item")
				return
		else:
			eprint("failed to put an item")
			return
		# TODO: make a "SLAP" noise for putting cup on the tray
		eprint("just put an item on the tray")
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

#	DebugOverlay.display("Tray item count %d" % items_container_object.get_child_count())

func put_item(item: Spatial) -> bool:
	if !items_container_object:
		return false
	var index = items_container_object.get_child_count()
	if index >= valid_item_locations.size():
		#take_items()
		return false
	var position: Position3D = valid_item_locations[index]
	item.transform = item.transform.scaled(Vector3(1.8, 1, 1.8))
	var origin = position.global_transform.origin
	items_container_object.add_child(item)
	item.global_transform.origin = origin
	print(" Item type %s" % item.coffee_type)
	OrderRepository.barista_add_item_to_delivery(item.coffee_type)
	return true

func take_items():
	if !items_container_object:
		return
	for i in items_container_object.get_children():
		var item_type = i.coffee_type
		i.queue_free()

func set_putting():
	should_ignore_clicks = false
	eprint("putting item...")
	state = States.WORKING
	# TODO: play animation of moving item from hands to tray
	var serve_duration: float = activity_place_item.duration
	timeout = get_node(@"/root/Game").time_elapsed + serve_duration
	var animation_player: AnimationPlayer = $"/root/Game".player_visual.get_node("baristaLowPoly/AnimationPlayer")
	animation_player.play("armsCarryEnd")

func is_empty() -> bool:
	return items_container_object.get_child_count() == 0

# TODO: convert this into speech baloons
func eprint(text: String):
	print("TRAY: %s" % text)

