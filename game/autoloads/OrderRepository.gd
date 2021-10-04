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

func get_coffe_name(coffee_type: int) -> String:
	if coffee_type in translations.keys():
		return translations[coffee_type]
	else:
		return ""

signal new_order(order_array)
signal removed_order
signal client_satisfied(node) #Called from customer directly
signal client_enraged(node) #Called from customer directly
signal client_got_order_from_counter
signal client_review(score)
#Stores the orders the player accepted
#node_ref:order_array
var order_queue:Dictionary = {

}

var barista_prepared_order:Array = []
var customer_waiting_on_ask_spot:Spatial = null

export var debugging = false

func _ready():
	connect("client_got_order_from_counter", self, "clean_barista_prepared_order")

func clean_barista_prepared_order()->void:
	barista_prepared_order.clear()

func barista_add_item_to_delivery(item:int)->void:
	barista_prepared_order.append(item)

#0 means garbage, #100 means excellent
func compare_order(barista_order:Array, customer_order:Array)->int:
	client_got_order_from_the_counter()
	var barista_order_siz = barista_order.size()
	var customer_order_size = customer_order.size()

	#Client will not accept missing items from the orders, also won't accept more than he is willingly to pay
	if barista_order_siz != customer_order_size:
		print("Reason: barista gave me missing/more items than I need", barista_order, customer_order)
		return 0

	var missed_items:float = 0
	for i in range(barista_order_siz):
		if barista_order[i] != customer_order[i]:
			missed_items += 1

	if missed_items == customer_order_size:
		print("All of the items are wrong")
		return 0
	else:
		print("Evaluated score: ")
		var score = (missed_items/customer_order_size)*100
		return 100-score

#Calls any client with a matching order
func barista_call_client_to_get_food(client_node:Spatial)->void:
	if client_node != null:
		if client_node.has_method("receive_order"):
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

func client_gave_review(review:float)->void:
	emit_signal("client_review", review)
	print("The customer gave a rating to the food: ", review)

func client_got_order_from_the_counter()->void:
	emit_signal("client_got_order_from_counter")

func get_order(node:Spatial)->Array:
	if not (node in order_queue.keys()):
		return []
	return order_queue[node]

func take_order_from_customer()->bool:
	if !customer_waiting_on_ask_spot or !is_instance_valid(customer_waiting_on_ask_spot):
		return false

	if not customer_waiting_on_ask_spot.has_method("deliver_order_to_barista"):
		printerr("The node is not a customer", get_stack())
		return false
	customer_waiting_on_ask_spot.deliver_order_to_barista()
	return true

func set_customer_waiting_on_ask_spot(node:Spatial)->void:
	customer_waiting_on_ask_spot = node

#This whole process is for debug purposes
func _process(delta):
	#Debug purposes
	if not debugging:
		return
	if customer_waiting_on_ask_spot == null:
		return
	if customer_waiting_on_ask_spot != null and not customer_waiting_on_ask_spot.barista_took_order:
		yield(get_tree().create_timer(rand_range(7, 20)), "timeout")
		take_order_from_customer()
	if order_queue.size() > 0:
		yield(get_tree().create_timer(rand_range(10, 20)), "timeout")
		for i in order_queue:
			barista_call_client_to_get_food(i)
