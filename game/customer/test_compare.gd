extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var client_order = [OrderRepository.possible_orders.coffee_americano]
var barista = [OrderRepository.possible_orders.coffee_americano]

func _ready():
	print(OrderRepository.compare_order(barista, client_order))
	client_order = OrderRepository.generate_order(2, false)
	barista = client_order.duplicate()
	print(OrderRepository.compare_order(barista, client_order))
	barista[0] = 99
	print(OrderRepository.compare_order(barista, client_order))
