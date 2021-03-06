extends Node

enum possible_orders {
	coffee_americano,
	coffee_espresso,
	coffee_latte,
	coffee_cappuccino
}

var translations:Dictionary = {
	possible_orders.coffee_americano:"Caffè Americano",
	possible_orders.coffee_espresso:"Espresso",
	possible_orders.coffee_latte:"Caffè latte",
	possible_orders.coffee_cappuccino:"Cappuccino",
}

var order_textures:Dictionary = {
	possible_orders.coffee_americano:load("res://art_assets/ui/logoCupAmericano.png"),
	possible_orders.coffee_espresso:load("res://art_assets/ui/logoCupEspresso.png"),
	possible_orders.coffee_latte:load("res://art_assets/ui/logoCupLatte.png"),
	possible_orders.coffee_cappuccino:load("res://art_assets/ui/logoCupCappuccino.png"),
}

func get_coffe_name(coffee_type: int) -> String:
	if coffee_type in translations.keys():
		return translations[coffee_type]
	else:
		return ""

signal new_order(order_array)
signal removed_order
signal client_satisfied(node, temper_delta) #Called from customer directly
signal client_unhappy(node, temper_delta) #Called from customer directly
signal client_enraged(node, temper_delta) #Called from customer directly
signal client_got_order_from_counter
signal client_review(score)
signal clicked_customer_to_deliver_beverage(customer)
#Stores the orders the player accepted
#node_ref:order_array
var order_queue:Dictionary = {

}

var barista_prepared_order:Array = []
var customer_waiting_on_ask_spot:GenericCustomer = null setget set_customer_waiting_on_ask_spot, get_customer_waiting_on_ask_spot
var _serving_tray:ServingTray = null setget set_serving_tray, get_serving_tray

func _ready():
	randomize()
	connect("client_got_order_from_counter", self, "clean_barista_prepared_order")
	connect("clicked_customer_to_deliver_beverage", self, "barista_call_client_to_get_food")

#Called from the Customer's CustomerClick.gd
func customer_clicked(customer:GenericCustomer):
	if not is_instance_valid(customer) or not customer.has_method("call_customer_to_deliver_zone"):
		printerr("Somehow it's trying to click an invalid customer! ", get_stack())
		return

	match customer.FSM.current_state:
		customer.FSM.waiting_for_order:
			if customer.barista_called_for_delivery:
				return
			emit_signal("clicked_customer_to_deliver_beverage", customer)
			print_debug("Called customer to deliver *beverage* ", customer)
		_:
			return

func emit_client_is_satisfied(node:GenericCustomer, temper_delta:float)->void:
	emit_signal("client_satisfied", node, temper_delta)

func emit_client_is_unhappy(node:GenericCustomer, temper_delta:float)->void:
	emit_signal("client_unhappy", node, temper_delta)

func emit_client_is_enraged(node:GenericCustomer, temper_delta:float)->void:
	emit_signal("client_enraged", node, temper_delta)

func clean_barista_prepared_order()->void:
	barista_prepared_order.clear()

func barista_add_item_to_delivery(item:int)->void:
	if not (item in possible_orders.values()):
		push_warning("[barista_add_item_to_delivery] The added item is not valid, the game will catch fire: {0} not any of {1}".format({0:str(item), 1:str(possible_orders.values())}))
	barista_prepared_order.append(item)

#Calls any customer to the deliver zone
func barista_call_client_to_get_food(client_node:GenericCustomer)->void:
	if is_instance_valid(client_node) and barista_prepared_order.size() > 0:
		if client_node.has_method("receive_order"):
			client_node.call_customer_to_deliver_zone()

#0 means garbage, #100 means excellent
func compare_order(barista_order:Array, customer_order:Array)->int:
	barista_order.sort()
	customer_order.sort()
	print_debug("[compare_order] Barista: {0}, Cutomer: {1}".format({0:str(barista_order), 1:str(customer_order)}))
	var barista_order_siz = barista_order.size()
	var customer_order_size = customer_order.size()

	#Client will not accept less items than the order size, won't mind if there's more than asked
	if barista_order_siz < customer_order_size:
		print_debug("[compare_order] barista gave less items than asked", barista_order, customer_order)
		return 0

	var missed_items:float = 0
	for i in range(barista_order_siz):
		if i < customer_order.size():
			if barista_order[i] != customer_order[i]:
				missed_items += 1

	client_got_order_from_the_counter()
	if missed_items == customer_order_size:
		print_debug("[compare_order] All of the items are wrong")
		return 0
	else:
		var score = (missed_items/customer_order_size)*100
		return 100-score


func generate_order(number_of_items:int, can_repeat:bool)->Array:
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

func add_order(node:GenericCustomer, order:Array)->void:
	if node in order_queue.keys():
		printerr("[add_order] Node already with some orders on queue, will skip")
		return
	order_queue[node] = order
	emit_signal("new_order", order )
	if !HintPopup.firstorderstart:
		HintPopup.firstorderstart = true
		HintPopup.display("The customer wants a drink, click on the machine to start making one", 5.0)
		HintPopup.display("Match the machine to the drink type", 5.0)

func remove_order(node:GenericCustomer)->bool:
	if not (node in order_queue.keys()):
		return false
	order_queue.erase(node)
	emit_signal("removed_order")
	return true

func client_gave_review(review:float)->void:
	emit_signal("client_review", review)
	print_debug("[client_gave_review] The customer gave a rating to the food: ", review)

func client_got_order_from_the_counter()->void:
	emit_signal("client_got_order_from_counter")

func get_order(node:GenericCustomer)->Array:
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

func set_customer_waiting_on_ask_spot(node:GenericCustomer)->void:
	customer_waiting_on_ask_spot = node

func get_customer_waiting_on_ask_spot()->GenericCustomer:
	return customer_waiting_on_ask_spot

func set_serving_tray(node:ServingTray)->void:
	_serving_tray = node

func get_serving_tray()->ServingTray:
	return _serving_tray

func is_serving_tray_empty()->bool:
	if not is_instance_valid(_serving_tray):
		return true
	return _serving_tray.is_empty()
