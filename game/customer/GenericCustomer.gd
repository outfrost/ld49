extends KinematicBody

enum states {idle, drinking, walking}
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

func find_seat():
	var seats = get_tree().get_nodes_in_group("drinking_spot")
	for i in seats:
		if not i.busy:
			i.busy = true
			target = i
			move_to(target.global_transform.origin)
			break

# Called when the node enters the scene tree for the first time.
func _ready():
	#locked_height = global_transform.origin.y
	find_seat()
	
func _physics_process(delta):
	if path_node < path.size():
		if current_state != states.walking:
			current_state = states.walking
			emit_signal("started_walking")
		var direction:Vector3 = path[path_node] - global_transform.origin
		if direction.length() < 0.1:
			path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			move_and_slide(direction.normalized() * current_speed, Vector3.UP)
			#global_transform.origin.y = locked_height
	else:
		if current_state == states.walking:
			current_state = states.idle
			emit_signal("started_idling")

func move_to(target):
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0
