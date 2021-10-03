class_name Interactable
extends Area

export(Resource) var activity

func _ready() -> void:
	connect("mouse_entered", self, "hover")
	pass

func _input_event(camera, event, click_position, click_normal, shape_idx):
	if !(event is InputEventMouseButton) or event.button_index != BUTTON_LEFT:
		return
	if activity and activity is Activity:
		print(activity)
		get_node(@"/root/Game").set_activity(activity)
	


func hover() -> void:
	# TODO: add outline effect to the object
		# NOTE: make sure there is only one object outlined at a time
	pass
