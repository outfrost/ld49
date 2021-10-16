class_name SpatialLabel
extends Sprite3D

onready var label: Label = $Viewport/Label

func _ready() -> void:
	hide()

func show_text(text: String) -> void:
	label.text = text
	show()
