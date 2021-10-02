# Copyright 2021 Outfrost
# This work is free software. It comes without any warranty, to the extent
# permitted by applicable law. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the LICENSE file for more details.

class_name Game
extends Node

onready var main_menu: Control = $UI/MainMenu
onready var transition_screen: TransitionScreen = $UI/TransitionScreen

var is_running = false

var temperature: int
export var temperature_initial: int = 20
export var temperature_max: int = 100

var temper: int
export var temper_initial: int = 100
export var temper_min: int = 0

# NOTE: should all be of type Activity
# TODO: attach them to scene objects with clickable models
export(Array, Resource) var activities
export(Array, Resource) var passive_effects

var activities_active = []
var current_activity_timeout: int = 0

var game_start_time: int
export var game_duration_seconds: int = 10
# TODO: convert into a timer node
var game_win_time_threshold: int

var current_activity: Activity
var last_activity_update: int = 0
var effects: Array = []

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

func _process(delta: float) -> void:
	DebugOverlay.display("fps %d" % Performance.get_monitor(Performance.TIME_FPS))
	
	
	if !is_running:
		return
	
	var tick_temperature_delta = 0
	var tick_temper_delta = 0
	var tick_money_delta = 0
	
	if passive_effects.size():
		for effect in passive_effects:
			if !effect:
				continue
			var should_tick = OS.get_ticks_msec() >= effect.next_update_time
			if should_tick:
				var tick_strings = [effect.displayed_name, effect.displayed_description]
				print("Passive effect tick \"%s\": %s" % tick_strings)
				tick_temperature_delta += effect.update_temperature_delta
				tick_temper_delta += effect.update_temper_delta
				tick_money_delta += effect.update_temperature_delta
				effect.bump_interval()
	
	temperature += tick_temperature_delta
	temper += tick_temper_delta
	
	var time_remaining = game_win_time_threshold - OS.get_ticks_msec()
	var time_remaining_s = time_remaining / 1000
	var time_remaining_ms = time_remaining % 1000
	DebugOverlay.display("time left: %s.%0*.3d" % [time_remaining_s, 3, time_remaining_ms])
	DebugOverlay.display("temper %s" % temper)
	DebugOverlay.display("temperature %s" % temperature)
	
	if current_activity:
		DebugOverlay.display("current activity %s" % current_activity.displayed_name)
		if OS.get_ticks_msec() >= current_activity_timeout:
			current_activity_timeout = 0
			current_activity = null
	else:
		DebugOverlay.display("current activity none")
		
	
	var is_out_of_temper = temper < 0
	var is_out_of_cool = temperature > temperature_max
	
	var is_lose_condition_met = is_out_of_temper or is_out_of_cool
	DebugOverlay.display("is_lose %s" % is_lose_condition_met)
	
	var is_win_condition_met = game_win_time_threshold <= OS.get_ticks_msec()
	DebugOverlay.display("is_win %s" % is_win_condition_met)
	
	if is_lose_condition_met:
		# TODO: implement gameover lose
		print("LOST")
		back_to_menu()
	
	if is_win_condition_met:
		# TODO: implement gameover win
		print("WON")
		back_to_menu()
	
	if Input.is_action_just_pressed("menu"):
		back_to_menu()

func on_start_game() -> void:
	main_menu.hide()
	temper = temper_initial
	temperature = temperature_initial
	game_start_time = OS.get_ticks_msec()
	game_win_time_threshold = game_start_time + (game_duration_seconds * 1000)
	is_running = true
	# TODO: populate activities
	# NOTE: activities should be a part of a level
	populate_activity_buttons()
	restart_passive_effects()

func back_to_menu() -> void:
	main_menu.show()
	clear_activity_buttons()
	is_running = false
	
func restart_passive_effects() -> void:
	if !passive_effects.size():
		return
	for i in range(0, passive_effects.size()):
		var pe = passive_effects[i]
		if !pe:
			continue
		pe.start_time = OS.get_ticks_msec()
		pe.bump_interval()

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
		activities_active.push_back(activity_object)

func clear_activity_buttons() -> void:
	if !activities_active.size():
		return
	for activity_object in activities_active:
		$UI.remove_child(activity_object.button)
	activities_active.clear()

func set_activity(activity) -> void:
	current_activity = activity
	current_activity_timeout = OS.get_ticks_msec() + activity.duration * 1000

