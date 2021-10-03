extends Control

onready var game = find_parent("Game")

func _ready() -> void:
	if !game:
		printerr("No Game controller found!")
		print_stack()
		return
	$BottomPanel/TryAgainButton.connect("pressed", game, "restart_game")
	$BottomPanel/BackToMenuButton.connect("pressed", game, "back_to_menu")

func show_game_lost() -> void:
	$TopPanel/Label1.text = "Oh no!"
	$TopPanel/Label2.text = "You lost!"
	update_stats_display()
	show()

func show_game_won() -> void:
	$TopPanel/Label1.text = "Well done!"
	$TopPanel/Label2.text = "You have surived the day!"
	update_stats_display()
	show()

func update_stats_display() -> void:
	$BottomPanel/TimeSurvivedValue.text = "%.0f seconds" % game.time_elapsed
	$BottomPanel/CustomersValue.text = "%d" % game.customers_served
