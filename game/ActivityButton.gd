extends Button
class_name ActivityButton

var activity: Activity

func _ready():
	pass

func _init(a):
	activity = a

func _pressed():
	get_node(@"/root/Game").set_activity(activity, null, "")
