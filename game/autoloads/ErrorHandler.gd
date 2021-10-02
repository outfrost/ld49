extends Node

#Handle and log errors returned from functions

func handle(err_code:int) -> void:
	if err_code != OK:
		printerr("An error has occurred ", err_code, get_stack())
