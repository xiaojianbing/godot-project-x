class_name AreaDebugOutline
extends Area2D


@export var outline_color: Color = Color(1.0, 0.85, 0.25, 0.95)
@export var outline_width: float = 2.0

@onready var _shape_node: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	visible = monitoring


func _process(_delta: float) -> void:
	visible = monitoring
	if visible:
		queue_redraw()


func _draw() -> void:
	if not visible or _shape_node == null:
		return
	var rect_shape := _shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return
	var half_size := rect_shape.size * 0.5
	var rect := Rect2(-half_size, rect_shape.size)
	draw_rect(rect, outline_color, false, outline_width)
