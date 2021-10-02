extends KinematicBody


enum states {idle, drinking, walking}

export var max_speed:float = 10
var current_speed:float = 0

var target:Spatial = null

var path = []
var path_node = 0
onready var navmesh:Navigation = get_parent()

onready var collision_raycast:RayCast = $RayCast

var locked_height:float = 0

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
	locked_height = global_transform.origin.y

	find_seat()


func _physics_process(delta):
	var colliding_with_customer = false
	if collision_raycast.is_colliding() and collision_raycast.get_collider().is_in_group("customer"):
		 colliding_with_customer = true #Reconsider life choices

	if path_node < path.size():
		var direction:Vector3 = path[path_node] - global_transform.origin
		if direction.length() < 1:
			path_node += 1
		else:
			current_speed = lerp(current_speed, max_speed, 0.01)
			move_and_slide(direction.normalized() * current_speed, Vector3.UP)
			global_transform.origin.y = locked_height

func move_to(target):
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0
