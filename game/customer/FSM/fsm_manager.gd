extends Node

enum {
	idle,
	waiting_to_order,
	waiting_for_order,
	drinking,
	walking,
	delivering_order_to_barista,
	picking_up_bewerage
}

onready var states = {
	idle:$idle,
	waiting_to_order:$waiting_to_order,
	waiting_for_order:$waiting_for_order,
	drinking:$drinking,
	walking:$walking,
	delivering_order_to_barista:$delivering_order_to_barista,
	picking_up_bewerage:$picking_up_bewerage
}

onready var current_state:int = idle

func _ready():
	change_state(idle)

func change_state(next_state:int)->void:
	states[current_state].exit()
	current_state = next_state
	states[next_state].enter()
