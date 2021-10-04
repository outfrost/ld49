extends KinematicBody

signal done_walking()

enum State {
	Idle,
	Walking,
	Busy,
}

const ACCEL_RATE: float = 5.0

export var max_speed: float = 2.0

onready var navmesh: Navigation = get_parent().find_node("Navigation")
onready var y_pos: float = transform.origin.y

var current_state = State.Idle
var current_speed: float = 0.0

var path = []
var path_node = 0

func _physics_process(delta):
	match current_state:
		State.Idle:
			if path_node < path.size():
				current_state = State.Walking
		State.Walking:
			if path_node < path.size():
				var move: Vector3 = path[path_node] - global_transform.origin
				if move.length() < 0.1:
					path_node += 1
				else:
					current_speed = lerp(current_speed, max_speed, delta * ACCEL_RATE)
					move_and_slide(move.normalized() * current_speed, Vector3.UP)
					transform.origin.y = y_pos
			else:
				current_state = State.Idle
				emit_signal("done_walking")
		State.Busy:
			pass
		_:
			printerr("Invalid Barista state? %s" % str(current_state))
			current_state = State.Idle

func move_to(target: Vector3):
	if !navmesh:
		printerr("Tried to move but navmesh had not been found")
		return
	path = navmesh.get_simple_path(global_transform.origin, target)
	path_node = 0
