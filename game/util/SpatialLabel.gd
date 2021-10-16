class_name SpatialLabel
extends Spatial

onready var label: Label = $SpatialLabelSprite/Viewport/Label

func _ready() -> void:
	hide()

func show_text(text: String) -> void:
	label.text = text
	show()
