extends Spatial


onready var hbox:HBoxContainer = $SpatialLabelSprite/Viewport/Control_SpeechBubble/CenterContainer/MarginContainer1/MarginContainer2/CenterContainer/HBoxContainer
onready var speechbubble:Control = $SpatialLabelSprite/Viewport/Control_SpeechBubble

export (Array, Texture) var order_textures

var visibility_transition:bool = false
var show:bool = false

#noderef:order_item
var sprites:Dictionary = {

}


func add_item(sprite:Texture, order_id:int)->bool:
	if sprite in sprites:
		return false
	if order_id > len(order_textures):
		printerr("Order id is greater than the amount of images for the orders ", get_stack())
		return false
	var texture:TextureRect = TextureRect.new()
	texture.expand = true
	texture.stretch_mode = TextureRect.STRETCH_SCALE_ON_EXPAND
	texture.rect_min_size = Vector2(32,32)
	texture.rect_size = texture.rect_min_size
	texture.size_flags_vertical = false
	hbox.add_child(texture)
	texture.texture = order_textures[order_id]
	sprites[texture] = order_id
	return true

func remove_item(order_id:int)->bool:
	for key in sprites:
		if sprites[key] == order_id:
			sprites.erase(key)
			key.queue_free()
			return true
	return false

func reset()->void:
	for key in sprites:
		sprites.erase(key)
		key.queue_free()

func render_orders(order_array:Array):
	reset()
	var childs = hbox.get_children()
	for i in childs:
		if not (i in sprites):
			i.queue_free()
	for order in order_array:
		var texture:Texture = OrderRepository.order_textures[order]
		add_item(texture, order)


func show_bubble():
	var current:Color = speechbubble.modulate
	var tween = $Tween
	tween.interpolate_property(speechbubble, "modulate",
		current, Color.white, 2,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func hide_bubble():
	var current:Color = speechbubble.modulate
	var tween = $Tween
	tween.interpolate_property(speechbubble, "modulate",
		current, Color.transparent, 2,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _ready():
	speechbubble.modulate = Color.transparent
