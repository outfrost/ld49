extends Control

func _ready() -> void:
	var game = find_parent("Game")
	if !game:
		printerr("No Game controller found!")
		print_stack()
		return
	$BottomPanel/TryAgainButton.connect("pressed", game, "restart_game")
	$BottomPanel/BackToMenuButton.connect("pressed", game, "back_to_menu")
