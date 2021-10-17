class_name Game
extends Node

onready var main_menu: Control = $UI/MainMenu
onready var transition_screen: TransitionScreen = $UI/TransitionScreen
onready var game_over_overlay: Control = $UI/GameOverOverlay

export var level_scene: PackedScene
onready var level_container: Node = $LevelContainer
var spawn_location: Position3D
var player_visual: Spatial
var level

export var skip_menus: bool = false

var is_running = false

# Barista's "cool" - the higher the better
var temper: float
export(float, 0.0, 200.0, 2.0) var temper_initial: float = 100.0
export(float, 0.0, 200.0, 2.0) var temper_min: float = 0.0
export(float, 35.0, 45.0, 0.1) var crazy_temper: float = 30.0
export(float, 0.0, 200.0, 2.0) var temper_max: float = 100.0

var time_elapsed: float = 0.0
export var game_duration: int = 20.0

export(Array, Resource) var passive_effects

var current_activity = null
var activity_started: bool = false
var current_activity_timeout: float = 0.0

var activity_queue = []

# NOTE: should all be of type Customer
# NOTE: should likely be a bunch of nodes in the scene graph somewhere
# TODO: populate customers
var customers: Array = []

var customers_served: int = 0

# Audio shit
onready var bus_music_tension: int = AudioServer.get_bus_index("MusicTension")
onready var bus_music_crazy: int = AudioServer.get_bus_index("MusicCrazy")
onready var bus_ambient: int = AudioServer.get_bus_index("Ambient")

var debug: Reference

func _ready() -> void:
	var debug_script_name = "res://debug.gd"
	if OS.has_feature("debug") and ResourceLoader.exists(debug_script_name):
		var debug_script = load(debug_script_name)
		debug = debug_script.new(self)
		debug.startup()

	AudioServer.set_bus_volume_db(bus_music_tension, linear2db(0.0))
	AudioServer.set_bus_volume_db(bus_music_crazy, linear2db(0.0))
	AudioServer.set_bus_volume_db(bus_ambient, linear2db(0.0))

	OrderRepository.connect("client_satisfied", self, "on_customer_satisfied")
	OrderRepository.connect("client_enraged", self, "on_customer_enraged")

	main_menu.connect("start_game", self, "on_start_game")
	if OS.has_feature("debug") and skip_menus:
		on_start_game()

func _process(delta: float) -> void:
	DebugOverlay.display("fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	if Input.is_action_just_pressed("menu"):
		back_to_menu()

	var is_crazy: bool = temper <= crazy_temper

	var target_tension_vol_linear = 0.0
	var target_crazy_vol_linear = 0.0
	if is_running and !is_crazy:
		target_tension_vol_linear = 1.0
	elif is_running and is_crazy:
		target_crazy_vol_linear = 1.0
	var target_ambient_vol_linear = 1.0

	var tension_vol_linear = db2linear(AudioServer.get_bus_volume_db(bus_music_tension))
	if target_tension_vol_linear > tension_vol_linear:
		tension_vol_linear = clamp(
			tension_vol_linear + delta * 0.25,
			tension_vol_linear,
			target_tension_vol_linear)
	else:
		tension_vol_linear = clamp(
			tension_vol_linear - delta * 0.25,
			target_tension_vol_linear,
			tension_vol_linear)
	AudioServer.set_bus_volume_db(bus_music_tension, linear2db(tension_vol_linear))

	var crazy_vol_linear = db2linear(AudioServer.get_bus_volume_db(bus_music_crazy))
	if target_crazy_vol_linear > crazy_vol_linear:
		crazy_vol_linear = clamp(
			crazy_vol_linear + delta * 0.25,
			crazy_vol_linear,
			target_crazy_vol_linear)
	else:
		crazy_vol_linear = clamp(
			crazy_vol_linear - delta * 0.25,
			target_crazy_vol_linear,
			crazy_vol_linear)
	AudioServer.set_bus_volume_db(bus_music_crazy, linear2db(crazy_vol_linear))

	var ambient_vol_linear = db2linear(AudioServer.get_bus_volume_db(bus_ambient))
	if target_ambient_vol_linear > ambient_vol_linear:
		ambient_vol_linear = clamp(
			ambient_vol_linear + delta * 0.25,
			ambient_vol_linear,
			target_ambient_vol_linear)
	else:
		ambient_vol_linear = clamp(
			ambient_vol_linear - delta * 0.25,
			target_ambient_vol_linear,
			ambient_vol_linear)
	AudioServer.set_bus_volume_db(bus_ambient, linear2db(ambient_vol_linear))

	if !is_running:
		return

	if is_crazy and !HintPopup.firstmindwarning:
		HintPopup.firstmindwarning = true
		HintPopup.display("Watch out, you're starting to lose it", 5.0)
		HintPopup.display("Keep an eye on your sanity, try slowing down or drinking a refreshing beverage", 5.0)

	time_elapsed += delta

	if passive_effects.size():
		for effect in passive_effects:
			if !effect:
				continue
			while effect.has_next_tick(time_elapsed):
				var tick_strings = [effect.displayed_name, effect.displayed_description]
				# print("Passive effect tick \"%s\": %s" % tick_strings)
				temper += effect.update_temper_delta

	try_pop_activity()
	if current_activity and activity_started:
		var activity = current_activity["activity"]
		var time_left = current_activity_timeout - time_elapsed
		var is_activity_over = time_left <= 0
#		DebugOverlay.display("current activity %s" % activity.displayed_name)
#		DebugOverlay.display("activity time left %s" % time_left)
		if is_activity_over:
			temper += activity.outcome_temper_delta
			current_activity_timeout = 0.0
			current_activity = null
			activity_started = false
#			if player_visual and spawn_location:
#				player_visual.transform = spawn_location.transform
#	else:
#		DebugOverlay.display("current activity none")

	# limit temper value
	if temper > temper_max:
		temper = temper_max

#	DebugOverlay.display("time remaining %.1f" % (game_duration - time_elapsed))
#	DebugOverlay.display("Your temper %.1f" % temper)

#	DebugOverlay.display("order queue size %d" % OrderRepository.order_queue.size())

#	if OrderRepository.order_queue.size():
#		for order in OrderRepository.order_queue.values():
#			var order_item_names := PoolStringArray()
#			for item_num in order:
#				order_item_names.push_back(OrderRepository.get_coffe_name(item_num))
#			var order_items_text = order_item_names.join(", ")
#			DebugOverlay.display(" - %s" % order_items_text)

	var is_out_of_temper = temper < temper_min

	if is_out_of_temper:
		# Game over
		# TODO: implement gameover lose
		print("LOST")
		is_running = false
		game_over_overlay.show_game_lost()

	if time_elapsed >= game_duration:
		# Player wins
		# TODO: implement gameover win
		print("WON")
		is_running = false
		game_over_overlay.show_game_won()

func on_start_game() -> void:
	if !OS.has_feature("debug") or !skip_menus:
		transition_screen.fade_in()
		yield(transition_screen, "animation_finished")

	main_menu.hide()
	$Background/Cafe.hide()
	$Background/Cafe/CameraPosition/Camera.current = false

	setup()

	transition_screen.fade_out()
	yield(transition_screen, "animation_finished")

	is_running = true
	on_started_running()

func back_to_menu() -> void:
	is_running = false

	transition_screen.fade_in()
	yield(transition_screen, "animation_finished")

	teardown()

	$Background/Cafe.show()
	$Background/Cafe/CameraPosition/Camera.current = true
	main_menu.show()

	transition_screen.fade_out()

func restart_game() -> void:
	is_running = false

	transition_screen.fade_in()
	yield(transition_screen, "animation_finished")

	teardown()
	setup()

	transition_screen.fade_out()
	yield(transition_screen, "animation_finished")

	is_running = true
	on_started_running()

func setup() -> void:
	reset()

	# Instantiate level
	level = level_scene.instance()
	level_container.add_child(level)

	spawn_location = level.find_node("PlayerSpawnLocation")
	player_visual = level.find_node("PlayerVisual")
	player_visual.connect("done_walking", self, "start_activity")

	restart_passive_effects()

func teardown() -> void:
	game_over_overlay.hide()
	HintPopup.reset()

	# Delete level instance
	level_container.remove_child(level)
	level.queue_free()

func reset() -> void:
	temper = temper_initial
	time_elapsed = 0.0
	customers_served = 0

	# Reset all the first time hints
	HintPopup.firstenrage = false
	HintPopup.firsthappy = false
	HintPopup.firstorder = false
	HintPopup.firstorderstart = false
	HintPopup.firstmachineuse = false
	HintPopup.firstmachinedone = false
	HintPopup.firstorderontray = false
	HintPopup.firsttempwarning = false
	HintPopup.firstmindwarning = false
	HintPopup.firstfridgeuse = false

	current_activity = null
	activity_started = false
	current_activity_timeout = 0.0
	OrderRepository.order_queue.clear()
	activity_queue.clear()
	customers.clear()

func on_started_running() -> void:
	yield(get_tree().create_timer(1.0), "timeout")
	HintPopup.display("Oh No! The AC unit died", 5.0)
	HintPopup.display("I guess you'll just have to try and keep your cool", 5.0)

func restart_passive_effects() -> void:
	if !passive_effects.size():
		return
	for pe in passive_effects:
		if !pe:
			continue
		pe.next_update_time = time_elapsed + pe.update_interval

func set_activity(activity: Activity, caller, callback_name: String, position: Position3D = null):
	var activity_queued = {
		"activity": activity,
		"caller": caller,
		"callback_name": callback_name,
		# NOTE: position might make sense as part of the activity??
		"position_marker": position,
	}
	activity_queue.push_back(activity_queued)
	var queue_length = activity_queue.size()
	print("queued an activity \"%s\", queue size: %s" % [activity.displayed_name, queue_length])

func try_pop_activity():
	if current_activity:
		return
	var activity_popped = activity_queue.pop_front()
	if !activity_popped:
		return
	var activity = activity_popped
	var position: Position3D = activity_popped["position_marker"]
	current_activity = activity
	if player_visual and position:
		player_visual.move_to(position.global_transform.origin)
	else:
		start_activity()

func start_activity():
	if !current_activity:
		return
	current_activity_timeout = time_elapsed + current_activity["activity"].duration
	if current_activity["caller"] and !current_activity["callback_name"].empty():
		current_activity["caller"].call(current_activity["callback_name"])
	var position: Position3D = current_activity["position_marker"]
	if player_visual and position:
		player_visual.rotation.y = position.rotation.y
	activity_started = true

func on_customer_satisfied(_customer) -> void:
	customers_served += 1
	$HappyNoiseSfx.play()
	if !HintPopup.firsthappy:
		HintPopup.firsthappy = true
		HintPopup.display("Good Job, the customer is satisfied", 5.0)
		HintPopup.display("Keep up the good work", 5.0)

func on_customer_enraged(_customer) -> void:
	$SadNoiseSfx.play()
	if !HintPopup.firstenrage:
		HintPopup.firstenrage = true
		HintPopup.display("Oh No, you made a customer upset", 5.0)
		HintPopup.display("If you're not careful, too many angry customers will take a toll on you", 5.0)
