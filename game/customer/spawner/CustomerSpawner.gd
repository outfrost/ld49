extends Spatial


#Send customer once there is a free spot, optionally wait some time
export (Array, PackedScene) var customer_scenes = []
var instanced_customers = []
onready var sitting_spots:Array = get_tree().get_nodes_in_group("drinking_spot")
onready var spawning_spots:Array = get_tree().get_nodes_in_group("spawning_spot")

onready var navigation_node:Navigation = get_parent()
onready var spawn_timer:Timer = $SpawnTimer


var time_passed = 0
export var randomize_time:bool = true
export (int, 0, 120) var random_seconds:int = 10
var waiting:bool = false

var game_is_running = true #Otherwise shut down the spawning, can be replaced for a more direct access

func spawn_customer():
	if not spawning_spots.empty():
		var spot = spawning_spots[randi() % spawning_spots.size()] #chooses random spawn spot based on the array
		var customer_packed:PackedScene = customer_scenes[randi() % customer_scenes.size()]
		var customer = customer_packed.instance()
		customer.global_transform.origin = spot.global_transform.origin
		navigation_node.add_child(customer)
		if randomize_time:
			spawn_timer.wait_time = randi() % random_seconds
	else:
		printerr("No spawning spots found!", get_stack())

func _on_SpawnTimer_timeout()->void:
	if has_free_seats():
		spawn_customer()

func has_free_seats()->bool:
	for i in sitting_spots:
		if not i.busy:
			return true
	return false
#manage the need for customers based on free spots
func _process(delta):
	if spawn_timer.is_stopped() && game_is_running:
		if has_free_seats():
			spawn_timer.start()

func _ready():
	yield(get_tree().create_timer(3), "timeout")
	spawn_customer()
