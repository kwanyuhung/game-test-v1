# checkout_counter.gd
class_name CheckoutCounter
extends Area2D

var _checkout_id: int
var _sprite: Sprite2D

signal checkout_interacted(checkout_id: int)

func _init() -> void:
	pass

func configure(id: int) -> void:
	_checkout_id = id

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _make_checkout_tex()
	add_child(_sprite)
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48.0, 24.0)
	col.shape = shape
	col.position = Vector2(24.0, 12.0)
	add_child(col)
	
	body_entered.connect(_on_body_entered)

func _make_checkout_tex() -> Texture2D:
	var img := Image.create(48, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Counter base
	_fill(0, 8, 48, 16, Color(0.48, 0.42, 0.54), img)
	_fill(0, 8, 48, 2, Color(0.58, 0.52, 0.64), img)   # top highlight
	# Conveyor belt
	_fill(0, 18, 48, 4, Color(0.35, 0.35, 0.38), img)
	# Register
	_fill(4, 2, 16, 12, Color(0.42, 0.48, 0.55), img)
	_fill(4, 2, 16, 2, Color(0.52, 0.58, 0.65), img)
	# Screen
	_fill(6, 4, 12, 6, Color(0.20, 0.35, 0.20), img)
	# Belt lines
	for x in range(0, 48, 6):
		_fill(x, 19, 2, 2, Color(0.50, 0.50, 0.52), img)
	return ImageTexture.create_from_image(img)

func _fill(x: int, y: int, w: int, h: int, col: Color, img: Image) -> void:
	x=clampi(x,0,48); y=clampi(y,0,24); w=clampi(w,0,48-x); h=clampi(h,0,24-y)
	for px in range(x,x+w):
		for py in range(y,y+h):
			img.set_pixel(px,py,col)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		checkout_interacted.emit(_checkout_id)

func get_checkout_id() -> int:
	return _checkout_id
