extends Control

const TEXT_SHOW_RATE: float = 1.5

onready var label: RichTextLabel = $Panel/RichTextLabel

var time_shown: float = 0.0
var duration: float = 0.0

var queue = []

# First time hint variables
var firstenrage: bool = false
var firstorder: bool = false
var firsthappy: bool = false
var firstorderstart: bool = false
var firstmachineuse: bool = false
var firstmachinedone: bool = false
var firstorderontray: bool = false
var firsttempwarning: bool = false
var firstmindwarning: bool = false
var firstfridgeuse: bool = false

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if !visible and !queue.empty():
		var disp = queue.pop_front()
		label.percent_visible = 0.0
		label.bbcode_text = disp.text
		time_shown = 0.0
		self.duration = disp.duration
		show()

	if time_shown > duration:
		hide()
		return
	label.percent_visible = clamp(time_shown * TEXT_SHOW_RATE, 0.0, 1.0)

	time_shown += delta

func reset() -> void:
	label.bbcode_text = ""
	label.percent_visible = 0.0
	time_shown = 0.0
	queue.clear()
	hide()

func display(text: String, duration: float) -> void:
	queue.push_back({ text = text, duration = duration })
