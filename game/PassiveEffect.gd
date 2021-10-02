class_name PassiveEffect
extends Resource

export var duratin_seconds: int = 5
export var update_interval_ms: int = 0
export var update_temper_delta: int = 0
export var update_money_delta: int = 0
export var update_temperature_delta: int = 0
export var displayed_name: String = ""
export var displayed_description: String = ""

var start_time: int = 0
var next_update_time: int = 0

func _ready():
	pass

func bump_interval() -> void:
	next_update_time = OS.get_ticks_msec() + update_interval_ms
