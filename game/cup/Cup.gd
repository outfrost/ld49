class_name Cup
extends Spatial

export(OrderRepository.possible_orders) var coffee_type

var coffee_materials:Dictionary ={
	OrderRepository.possible_orders.coffee_americano:load("res://assets/imports/ColorBand_Americano.tres"),
	OrderRepository.possible_orders.coffee_cappuccino:load("res://assets/imports/ColorBand_Cappuccino.tres"),
	OrderRepository.possible_orders.coffee_espresso:load("res://assets/imports/ColorBand_Espresso.tres"),
	OrderRepository.possible_orders.coffee_latte:load("res://assets/imports/ColorBand_Latte.tres")
}

func _ready():
	if $paper_cup_ready_exportprep.has_node("PaperCup_Ready"):
		$paper_cup_ready_exportprep/PaperCup_Ready.set_surface_material(1, coffee_materials[coffee_type])
	else:
		print("Model does not have expected node 'PaperCup_Ready'")

