extends KinematicBody

signal done_walking()

enum State {
	Idle,
	Walking,
	Busy,
}

enum possible_icons {
	barista_hot,
	barista_insane
}

var icon_scenes: Dictionary = {
	possible_icons.barista_hot:load("res://assets/Icon_Hot.tscn"),
	possible_icons.barista_insane:load("res://assets/Icon_Insane.tscn")
}

const ACCEL_RATE: float = 2.0

export var max_speed: float = 3.0

onready var anim = $baristaLowPoly/AnimationPlayer
onready var cooling_off_sfx = $CoolingOffSfx
onready var frustrated_sfx = $FrustratedSfx
onready var very_frustrated_sfx = $VeryFrustratedSfx
onready var frustrated_sfx_timer = $FrustratedSfxDelay

onready var navmesh: Navigation = get_parent().find_node("Navigation")
onready var y_pos: float = transform.origin.y

onready var game: Game = find_parent("Game")

var current_state = State.Idle
var current_speed: float = 0.0

var path = []
var path_node = 0

var carry_attachment: BoneAttachment
onready var icon_attachment: Node = $Icon
onready var displayed_icon:int = -1

func _ready() -> void:
	anim.get_animation("walkFast").loop = true
	anim.get_animation("walkFastCarrying").loop = true

	# Starting pose: end of walk cycle
	anim.play("walkFast")
	anim.seek(anim.current_animation_length, true)
	anim.stop(false)

	carry_attachment = BoneAttachment.new()
	carry_attachment.bone_name = "baristaCarried"
	$baristaLowPoly/baristaArmature/Skeleton.add_child(carry_attachment)

	OrderRepository.connect("client_unhappy", self, "react_to_customer_unhappy")
	OrderRepository.connect("client_enraged", self, "react_to_customer_unhappy")

func _physics_process(delta):
	match current_state:
		State.Idle:
			if path_node < path.size():
				current_state = State.Walking
				var animation_name = "walkFast" if is_emptyhanded() else "walkFastCarrying"
				anim.play(animation_name, -1.0, max_speed)
		State.Walking:
			if path_node < path.size():
				var move: Vector3 = path[path_node] - global_transform.origin
				if move.length() < 0.1:
					path_node += 1
				else:
					current_speed = lerp(current_speed, max_speed, delta * ACCEL_RATE)
					move_and_slide(move.normalized() * current_speed, Vector3.UP)
					transform.origin.y = y_pos
					var direction:Vector3 = move.normalized()
					rotation.y = lerp(rotation.y, atan2(direction.x, direction.z), 0.1)
			else:
				current_state = State.Idle
				anim.stop()
				emit_signal("done_walking")
		State.Busy:
			pass
		_:
			printerr("Invalid Barista state? %s" % str(current_state))
			current_state = State.Idle

func _process(delta:float) -> void:
#	DebugOverlay.display("Cups in hand %d" % carry_attachment.get_child_count())
	pass

func move_to(target: Vector3):
	if !navmesh:
		printerr("Tried to move but navmesh had not been found")
		return
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0

func take_cup(coffee_type: int) -> bool:
	var cup_reference = $CupReference
	if carry_attachment.get_child_count():
		return false
	#var item_position = $ItemLocations/Position3D
	print("placing an item in barista's hands")

	#var origin = item_position.global_transform.origin
	var cup = cup_reference.duplicate()
	cup.coffee_type = coffee_type
	carry_attachment.add_child(cup)
	cup.visible = true
	#cup.global_transform.origin = origin
	return true

func is_emptyhanded() -> bool:
	return carry_attachment.get_child_count() == 0

func remove_cup():
	var cup: Cup = null
	for item in carry_attachment.get_children():
		if item is Cup:
			cup = item
		item.queue_free()
	if cup:
		return cup.coffee_type
	return null

func add_icon(icon_type:int) -> void:
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

func react_to_customer_unhappy(_node, _temper_delta) -> void:
	frustrated_sfx_timer.start()
	yield(frustrated_sfx_timer, "timeout")
	if game.temper < game.crazy_temper:
		very_frustrated_sfx.play()
	else:
		frustrated_sfx.play()
