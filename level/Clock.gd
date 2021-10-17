extends Spatial

onready var game = find_parent("Game")
onready var hourHand = $ClockArmature/Skeleton/HourHand001
onready var minuteHand = $ClockArmature/Skeleton/MinuteHand001

func _process(delta) -> void:
	update_clock()

func update_clock():
	var completion = game.time_elapsed/game.game_duration

	var hourHand_Position = TAU * completion * -1
	var minuteHand_Position = TAU * completion * 16 * -1

	hourHand.rotation.z=hourHand_Position
	minuteHand.rotation.z=minuteHand_Position
