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
signal client_satisfied(node) #Called from customer directly
signal client_enraged(node) #Called from customer directly

#Stores the orders the player accepted
#node_ref:order_array
var order_queue:Dictionary = {

}

var barista_prepared_order:Array = []
var customer_waiting_on_ask_spot:Spatial = null

func barista_add_item_to_delivery(item:int)->void:
	barista_prepared_order.append(item)

#0 means garbage, #100 means excellent
func compare_order(barista_order:Array, customer_order:Array)->int:
	var barista_order_siz = barista_order.size()
	var customer_order_size = customer_order.size()
	
	#Client will not accept missing items from the orders, also won't accept more than he is willingly to pay
	if barista_order_siz != customer_order_size:
		 return 0
	
	var missed_items:float = 0
	for i in range(barista_order_siz):
		if barista_order[i] != customer_order[i]:
			missed_items += 1
	
	if missed_items == customer_order_size:
		return 0
	else:
		return (customer_order_size/(customer_order_size-missed_items) )*100

#Calls any client with a matching order
func barista_call_client_to_get_food(client_node:Spatial)->void:
	if client_node.has("receive_order"):
		client_node.call_customer_to_deliver_zone()

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

func get_order(node:Spatial)->Array:
	if not (node in order_queue.keys()):
		return []
	return order_queue[node]

func take_order_from_customer()->bool:
	if customer_waiting_on_ask_spot == null:
		return false
	if not customer_waiting_on_ask_spot.has_method("deliver_order_to_barista"):
		printerr("The node is not a customer", get_stack())
		return false
	customer_waiting_on_ask_spot.deliver_order_to_barista()
	return true

func set_customer_waiting_on_ask_spot(node:Spatial)->void:
	customer_waiting_on_ask_spot = node
