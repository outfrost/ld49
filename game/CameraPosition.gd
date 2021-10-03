extends Spatial

const ZOOM_INCREMENT: float = 0.1
const CAMERA_LERP_RATE: float = 12.0

export var min_zoom_translation: Vector3 = Vector3(0.0, 8.0, 5.75)
export var min_zoom_rotation: Vector3 = Vector3(-55.0, 0.0, 0.0)

export var max_zoom_translation: Vector3 = Vector3(0.0, 3.5, 4.0)
export var max_zoom_rotation: Vector3 = Vector3(-35.0, 0.0, 0.0)

onready var camera: Camera = $Camera

var min_zoom_transform: Transform = Transform.IDENTITY
var max_zoom_transform: Transform = Transform.IDENTITY

var zoom: float = 0.5

func _ready() -> void:
	min_zoom_transform = min_zoom_transform \
		.rotated(Vector3.RIGHT, deg2rad(min_zoom_rotation.x)) \
		.rotated(Vector3.UP, deg2rad(min_zoom_rotation.y)) \
		.rotated(Vector3.FORWARD, deg2rad(min_zoom_rotation.z))

	min_zoom_transform.origin = min_zoom_translation

	max_zoom_transform = max_zoom_transform \
		.rotated(Vector3.RIGHT, deg2rad(max_zoom_rotation.x)) \
		.rotated(Vector3.UP, deg2rad(max_zoom_rotation.y)) \
		.rotated(Vector3.FORWARD, deg2rad(max_zoom_rotation.z))

	max_zoom_transform.origin = max_zoom_translation

func _process(delta: float) -> void:
	if Input.is_action_just_released("zoom_in"):
		zoom = clamp(zoom + ZOOM_INCREMENT, 0.0, 1.0)
	if Input.is_action_just_released("zoom_out"):
		zoom = clamp(zoom - ZOOM_INCREMENT, 0.0, 1.0)

	var target_camera_xform = min_zoom_transform.interpolate_with(max_zoom_transform, zoom)

	camera.transform = camera.transform.interpolate_with(
		target_camera_xform,
		clamp(delta * CAMERA_LERP_RATE, 0.0, 1.0))
