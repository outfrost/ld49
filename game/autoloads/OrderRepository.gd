extends Node

enum possible_orders {
	coffee_americano,
	coffee_expresso,
	coffee_latte,
	coffee_cappuccino
}

var translations:Dictionary = {
	possible_orders.coffee_americano:"Coffee americano",
	possible_orders.coffee_expresso:"Coffee expresso",
	possible_orders.coffee_latte:"Coffee latte",
	possible_orders.coffee_cappuccino:"Coffee cappuccino",
}

signal new_order(order_array)
signal removed_order
signal client_satisfied(node)
signal client_enraged(node)

#node_ref:order_array
var order_queue:Dictionary = {

}

var barista_prepared_order:Array = []

func barista_add_item_to_delivery(item:int)->void:
	barista_prepared_order.append(item)

func barista_call_client_to_get_order()->void:
	barista_prepared_order.sort()
	for client_order in order_queue:
		pass

var customer_waiting_on_ask_spot:Spatial = null

func generate_order(number_of_items:int, can_repeat:bool)->Array:
	randomize()
	if number_of_items > possible_orders.size():
		can_repeat = true

	var chosen_items = []
	for i in range(number_of_items):
		var order = randi() % possible_orders.size()
		if not can_repeat and order in chosen_items:
			while(order in chosen_items):
				order = randi() % possible_orders.size()
		chosen_items.append(order)
	return chosen_items

func add_order(node:Spatial, order:Array)->void:
	if node in order_queue.keys():
		printerr("Node already with some orders on queue")
		return
	order_queue[node] = order
	emit_signal("new_order", order )

func remove_order(node:Spatial)->bool:
	if not (node in order_queue.keys()):
		return false
	order_queue.erase(node)
	emit_signal("removed_order")
	return true

func take_order_from_customer()->void:
	if customer_waiting_on_ask_spot == null:
		return
	if not customer_waiting_on_ask_spot.has_method("deliver_order_to_barista"):
		printerr("The node is not a customer", get_stack())
		return
	customer_waiting_on_ask_spot.deliver_order_to_barista()

func set_customer_waiting_on_ask_spot(node:Spatial)->void:
	customer_waiting_on_ask_spot = node
