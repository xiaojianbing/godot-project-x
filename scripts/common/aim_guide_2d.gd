class_name AimGuide2D
extends Node2D


@export var guide_length: float = 200.0
@export var guide_color: Color = Color(0.38, 0.92, 1.0, 0.9)
@export var guide_width: float = 2.0

var _active: bool = false
var _direction: Vector2 = Vector2.RIGHT


func set_guide(active: bool, direction: Vector2) -> void:
	_active = active
	visible = active
	if direction.length_squared() > 0.001:
		_direction = direction.normalized()
	if active:
		queue_redraw()


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var end_point := _direction * guide_length
	draw_line(Vector2.ZERO, end_point, guide_color, guide_width)
	draw_circle(end_point, 2.5, guide_color)
