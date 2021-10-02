extends KinematicBody


enum states {idle, drinking, walking}

export var max_speed:float = 10
var current_speed:float = 0

var target:Spatial = null

var path = []
var path_node = 0
onready var navmesh:Navigation = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	var seats = get_tree().get_nodes_in_group("drinking_spot")
	for i in seats:
		if not i.busy:
			target = i
			i.busy = true
			move_to(target.global_transform.origin)


func _physics_process(delta):
	if path_node < path.size():
		var direction:Vector3 = path[path_node] - global_transform.origin
		if direction.length() < 1:
			path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			move_and_slide(direction.normalized() * current_speed, Vector3.UP)

func move_to(target):
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0
