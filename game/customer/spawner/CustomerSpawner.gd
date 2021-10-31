extends Spatial


#Send customer once there is a free spot, optionally wait some time
var spots_collection = load("res://game/customer/spots/SpotsGroupList.gd").new()

export (Array, PackedScene) var customer_scenes = []
var instanced_customers = []

onready var sitting_spots:Array = get_tree().get_nodes_in_group(spots_collection.spot_names[spots_collection.drinking_spot])
onready var spawning_spots:Array = get_tree().get_nodes_in_group(spots_collection.spot_names[spots_collection.spawning_spot])
onready var waiting_spots:Array = get_tree().get_nodes_in_group(spots_collection.spot_names[spots_collection.waiting_spot])

onready var navigation_node:Navigation = get_parent()
onready var spawn_timer:Timer = $SpawnTimer

var time_passed = 0
export var randomize_time:bool = true
export (int, 0, 120) var random_seconds:int = 10
export var endgame_decline_offset: int	# offset from the max game time when spawn rate starts decreasing
var waiting:bool = false

var game_manager_node:Node

var increasing_difficulty:bool = true
var decreasing_difficulty:bool = false
var current_max_customers = 10
var global_max_customers = 50 #Won't override the available seats

func customer_despawning(node:Spatial)->void:
	instanced_customers.erase(node)

func spawn_customer()->void:
	#Game isn't running, abort
	if not game_manager_node.is_running:
		return

	#Must have free spawning spots, free seats, and less customers than the limit
	if not spawning_spots.empty() and has_free_seats() and instanced_customers.size() < current_max_customers:
		var spot = spawning_spots[randi() % spawning_spots.size()] #chooses random spawn spot based on the array
		var customer_packed:PackedScene = customer_scenes[randi() % customer_scenes.size()]
		var customer = customer_packed.instance()
		navigation_node.add_child(customer)
		instanced_customers.append(customer)
		customer.global_transform.origin = spot.global_transform.origin
		customer.connect("despawning", self, "customer_despawning")
		if randomize_time:
			spawn_timer.wait_time = rand_range(1,random_seconds)
	else:
		return

func _on_SpawnTimer_timeout()->void:
	if has_free_seats():
		spawn_customer()

func has_free_seats()->bool:
	#return true
	var free_seats = false
	for i in sitting_spots:
		if not i.busy:
			free_seats = true

	if instanced_customers.size() >= waiting_spots.size():
		free_seats = false
	return free_seats

#Manage the need of new customers based on free spots
func _process(delta):
	if spawn_timer.is_stopped() && game_manager_node.is_running:
		if has_free_seats():
			spawn_timer.start()

func _ready():
	Engine.time_scale = 3
	add_child(spots_collection)
	game_manager_node = find_parent("Game")
	if is_instance_valid(game_manager_node):
		spawn_timer.start()
	else:
		printerr("[CustomerSpawner] Could not find the Game node, customers will not spawn ", get_stack())

#Increase the difficulty (customer limit) by 1 until the limit is reached, then decrease by 1 until 0
func _on_RampDifficultyTimer_timeout()->void:
	if increasing_difficulty:
		current_max_customers+=1
		print_debug("[CustomerSpawner] Increased limit of customers ", current_max_customers)
		if current_max_customers == global_max_customers:
			increasing_difficulty = false
	elif !decreasing_difficulty and game_manager_node.time_elapsed >= game_manager_node.game_duration - endgame_decline_offset:
		decreasing_difficulty = true
	elif decreasing_difficulty:
		if current_max_customers > 5:
			print_debug("[CustomerSpawner] Decreased limit of customers ", current_max_customers)
			current_max_customers-=1
		elif current_max_customers > 0:
			print_debug("[CustomerSpawner] Decreased limit of customers ", current_max_customers)
			current_max_customers-=2
