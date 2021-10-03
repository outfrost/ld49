extends KinematicBody

#Generic Customer script
#Implements path finding, order delivery and mood


enum states {idle, waiting_to_order, waiting_for_order, drinking, walking}
enum feelings {happy, indifferent, bored, insane}

var current_state = states.idle

export var max_speed:float = 10
var current_speed:float = 0

var target:Spatial = null

var path = []
var path_node = 0
onready var navmesh:Navigation = get_parent()

var locked_height:float = 0

signal waiting_for_drink
signal started_walking
signal started_idling

#Maybe for some reason the characters are supposed to be locked on the y axis, so they don't climb stuff, not that they will or should
#I'm not sure if they would climb stairs by default

var lock_z_axis:bool = false

func find_seat():
	var seats = get_tree().get_nodes_in_group("drinking_spot")
	for i in seats:
		if not i.busy:
			i.set_busy(true)
			i.update()
			target = i
			move_to(target.global_transform.origin)
			break

func leave_and_go_away():
	if target.has_method("leave"):
		target.leave() #current allocated seat
	var exit_spots:Array = get_tree().get_nodes_in_group("exit_spot")
	var chosen_exit:Spatial = exit_spots[randi() % exit_spots.size()]
	target = chosen_exit

# Called when the node enters the scene tree for the first time.
func _ready():
	if lock_z_axis:
		locked_height = global_transform.origin.y
	find_seat()
	
func _physics_process(delta):
	if path_node < path.size(): #Must move to reach destination
		if current_state != states.walking:
			current_state = states.walking
			emit_signal("started_walking")
		var direction:Vector3 = path[path_node] - global_transform.origin
		if direction.length() < 0.1:
			path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			move_and_slide(direction.normalized() * current_speed, Vector3.UP)
			if lock_z_axis:
				global_transform.origin.y = locked_height
	else: #Reached destination
		match current_state:
			states.idle:
				pass
			states.walking:
				current_state = states.idle
				emit_signal("started_idling")
				if target.is_in_group("drinking_spot"):
					current_state = states.waiting_to_order
				if target.is_in_group("exit_spot"):
					call_deferred("queue_free")
			states.waiting_to_order:
				#TODO: implement orders
				pass
			states.waiting_for_order:
				#TODO: implement waiting for order
				pass
			states.drinking:
				#TODO: implement customer drinking/eating
				pass
			_:
				current_state = states.idle

func move_to(target):
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0
