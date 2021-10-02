# Copyright 2021 Outfrost
# This work is free software. It comes without any warranty, to the extent
# permitted by applicable law. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

class_name Activity
extends Resource

export var duration: int = 5 # seconds
export var outcome_temper_delta: int = 0
export var outcome_money_delta: int = 0
export var outcome_temperature_delta: int = 0
export var displayed_name: String = ""

func _ready():
	pass

func _init():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
