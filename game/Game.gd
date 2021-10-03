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

# Barista's temperature - the lower the better
var temperature: float
export(float, 35.0, 45.0, 0.1) var temperature_initial: float = 37.0
export(float, 35.0, 45.0, 0.5) var temperature_max: float = 40.0

# Barista's "cool" - the higher the better
var temper: float
export(float, 0.0, 200.0, 2.0) var temper_initial: float = 100.0
export(float, 0.0, 200.0, 2.0) var temper_min: float = 0.0
export(float, 0.0, 200.0, 2.0) var temper_max: float = 100.0

var time_elapsed: float = 0.0
export var game_duration: int = 20.0

# NOTE: should all be of type Activity
# TODO: attach them to scene objects with clickable models
export(Array, Resource) var activities

export(Array, Resource) var passive_effects

var activities_available = []
var current_activity: Activity
var current_activity_timeout: float = 0.0

var activity_queue = []

# NOTE: should all be of type Customer
# NOTE: should likely be a bunch of nodes in the scene graph somewhere
# TODO: populate customers
var customers: Array = []

var debug: Reference

func _ready() -> void:
	var debug_script_name = "res://debug.gd"
	if OS.has_feature("debug") and ResourceLoader.exists(debug_script_name):
		var debug_script = load(debug_script_name)
		debug = debug_script.new(self)
		debug.startup()

	main_menu.connect("start_game", self, "on_start_game")
	if skip_menus:
		on_start_game()

func _process(delta: float) -> void:
	DebugOverlay.display("fps %d" % Performance.get_monitor(Performance.TIME_FPS))

	if Input.is_action_just_pressed("menu"):
		back_to_menu()

	if !is_running:
		return

	time_elapsed += delta

	if passive_effects.size():
		for effect in passive_effects:
			if !effect:
				continue
			while effect.has_next_tick(time_elapsed):
				var tick_strings = [effect.displayed_name, effect.displayed_description]
				# print("Passive effect tick \"%s\": %s" % tick_strings)
				temperature += effect.update_temperature_delta
				temper += effect.update_temper_delta
#				tick_money_delta += effect.update_temperature_delta

	try_pop_activity()
	if current_activity:
		var time_left = current_activity_timeout - time_elapsed
		var is_activity_over = time_left <= 0
		DebugOverlay.display("current activity %s" % current_activity.displayed_name)
		DebugOverlay.display("activity time left %s" % time_left)
		if is_activity_over:
			temperature += current_activity.outcome_temperature_delta
			temper += current_activity.outcome_temper_delta
			current_activity_timeout = 0.0
			current_activity = null
			if player_visual and spawn_location:
				player_visual.transform = spawn_location.transform
	else:
		DebugOverlay.display("current activity none")

	# limit temper value
	if temper > temper_max:
		temper = temper_max

	DebugOverlay.display("time remaining %.1f" % (game_duration - time_elapsed))
	DebugOverlay.display("temper %.1f" % temper)
	DebugOverlay.display("temperature %.2f" % temperature)

	var is_out_of_temper = temper < temper_min
	var is_out_of_cool = temperature > temperature_max

	if is_out_of_temper or is_out_of_cool:
		# Game over
		# TODO: implement gameover lose
		print("LOST")
		is_running = false
		game_over_overlay.show()

	if time_elapsed >= game_duration:
		# Player wins
		# TODO: implement gameover win
		print("WON")
		is_running = false
		game_over_overlay.show()

func on_start_game() -> void:
	if !skip_menus:
		transition_screen.fade_in()
		yield(transition_screen, "animation_finished")

	main_menu.hide()

	reset()

	# Instantiate level
	level = level_scene.instance()
	level_container.add_child(level)
	
	spawn_location = level.find_node("PlayerSpawnLocation")
	player_visual = level.find_node("PlayerVisual")

	# TODO: populate activities
	# NOTE: activities should be a part of a level
	populate_activity_buttons()
	restart_passive_effects()

	transition_screen.fade_out()
	yield(transition_screen, "animation_finished")

	is_running = true

func back_to_menu() -> void:
	is_running = false

	transition_screen.fade_in()
	yield(transition_screen, "animation_finished")

	game_over_overlay.hide()

	# Delete level instance
	level_container.remove_child(level)
	level.queue_free()

	clear_activity_buttons()

	main_menu.show()

	transition_screen.fade_out()

func restart_game() -> void:
	is_running = false

	transition_screen.fade_in()
	yield(transition_screen, "animation_finished")

	game_over_overlay.hide()

	# Delete level instance
	level_container.remove_child(level)
	level.queue_free()

	clear_activity_buttons()

	reset()

	# Instantiate level
	level = level_scene.instance()
	level_container.add_child(level)

	# TODO: populate activities
	# NOTE: activities should be a part of a level
	populate_activity_buttons()
	restart_passive_effects()

	transition_screen.fade_out()
	yield(transition_screen, "animation_finished")

	is_running = true

func reset() -> void:
	temper = temper_initial
	temperature = temperature_initial
	time_elapsed = 0.0

func restart_passive_effects() -> void:
	if !passive_effects.size():
		return
	for pe in passive_effects:
		if !pe:
			continue
		pe.next_update_time = time_elapsed + pe.update_interval

func populate_activity_buttons() -> void:
	if !activities.size():
		return

	for i in range(0, activities.size()):
		var activity = activities[i]
		if !activity:
			continue

		var activity_button = ActivityButton.new(activity)
		activity_button.text = activity.displayed_name
		activity_button.rect_position = Vector2(20, 150 + i * 30)
		$UI.add_child(activity_button)
		var activity_object = {
			"button": activity_button,
			"activity": activity
		}
		activities_available.push_back(activity_object)

func clear_activity_buttons() -> void:
	if !activities_available.size():
		return
	for activity_object in activities_available:
		$UI.remove_child(activity_object.button)
	activities_available.clear()

func set_activity(activity: Activity, caller, callback_name: String, position: Position3D = null):
	var activity_queued = {
		"activity": activity,
		"caller": caller,
		"callback_name": callback_name,
		# NOTE: position might make sense as part of the activity??
		"position_marker": position,
		# TODO: make it possible for activity to also suggest player animation
		#"animation": ""
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
	var activity = activity_popped["activity"]
	var position: Position3D = activity_popped["position_marker"]
	activity_popped["caller"].call(activity_popped["callback_name"])
	if activity_popped["position_marker"]:
		# TODO: teleport player to the marker and set their rotation
		pass
	current_activity = activity
	current_activity_timeout = time_elapsed + activity.duration
	if player_visual and position:
		player_visual.transform = position.global_transform

