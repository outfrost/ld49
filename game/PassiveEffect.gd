class_name PassiveEffect
extends Resource

#export var duration: float = 3.0 # seconds
export var update_interval: float = 1.0 # seconds
export var update_temper_delta: float = 0.0
#export var update_money_delta: int = 0
export var update_temperature_delta: float = 0.0
export var displayed_name: String = ""
export var displayed_description: String = ""

var next_update_time: float = 0.0

func _ready():
	pass

func has_next_tick(time_elapsed: float) -> bool:
	if time_elapsed >= next_update_time:
		next_update_time += update_interval
		return true
	else:
		return false
