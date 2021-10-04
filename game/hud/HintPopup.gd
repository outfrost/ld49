extends Control

const TEXT_SHOW_RATE: float = 1.5

onready var label: RichTextLabel = $Panel/RichTextLabel

var time_shown: float = 0.0
var duration: float = 0.0

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	time_shown += delta
	if time_shown > duration:
		hide()
		return
	label.percent_visible = clamp(time_shown * TEXT_SHOW_RATE, 0.0, 1.0)

func reset() -> void:
	label.bbcode_text = ""
	label.percent_visible = 0.0
	time_shown = 0.0
	hide()

func display(text: String, duration: float) -> void:
	reset()
	label.bbcode_text = text
	self.duration = duration
	show()
