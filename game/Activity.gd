class_name Activity
extends Resource

export var duration: float = 3.0 # seconds
export var outcome_temper_delta: float = 0.0
#export var outcome_money_delta: int = 0.0
export var displayed_name: String = ""

func _ready():
	pass

func _init(name: String = "", duration: float = 3.0, temper: float = 0.0):
	self.duration = duration
	self.outcome_temper_delta = temper
	self.displayed_name = name


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
