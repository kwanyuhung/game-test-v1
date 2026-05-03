# product.gd
# Product class — represents a single supermarket product.

class_name Product

var id: String
var name: String
var price: float
var color: Color
var shape: int    # 0=round, 1=rectangle, 2=bottle, 3=box
var category: String

func _init(p_id: String, p_name: String, p_price: float, p_color: Color, p_shape: int, p_cat: String):
	id = p_id
	name = p_name
	price = p_price
	color = p_color
	shape = p_shape
	category = p_cat
