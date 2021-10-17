extends Control

export var color_angry:Color
export var color_calm:Color

onready var game = find_parent("Game")

func _process(delta:float) -> void:
	update_bar()

func update_bar() -> void:

	var length = inverse_lerp(game.temper_min, game.temper_max, game.temper)
	var barHue = fmod(lerp(color_angry.h +1.0, color_calm.h, length), 1.0)

	$TextureRect/ProgressBar.value = length
	$TextureRect/ProgressBar.self_modulate = Color.from_hsv(barHue,lerp(color_angry.s, color_calm.s, length),lerp(color_angry.v, color_calm.v, length))
