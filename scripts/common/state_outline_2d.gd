class_name StateOutline2D
extends Node2D


@export var outline_size: Vector2 = Vector2(26.0, 38.0)
@export var outline_color: Color = Color(0.42, 1.0, 0.82, 0.95)
@export var outline_width: float = 2.0

var _active: bool = false


func set_active(active: bool) -> void:
	if _active == active:
		return
	_active = active
	visible = active
	if active:
		queue_redraw()


func set_outline_color(color: Color) -> void:
	outline_color = color
	if _active:
		queue_redraw()


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var rect := Rect2(-outline_size * 0.5, outline_size)
	draw_rect(rect, outline_color, false, outline_width)
