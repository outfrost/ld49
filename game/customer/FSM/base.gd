extends Node

onready var base_customer = get_parent().get_parent()
onready var FSM:Node = get_parent()

var active:bool = false

func enter():
	active = true
	return

func exit():
	active = false
	return
