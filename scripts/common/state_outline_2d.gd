class_name StateOutline2D
extends Node2D


@export var outline_size: Vector2 = Vector2(26.0, 38.0)
@export var outline_color: Color = Color(0.42, 1.0, 0.82, 0.95)
@export var front_outline_color: Color = Color(0.42, 1.0, 0.82, 0.95)
@export var back_outline_color: Color = Color(0.32, 0.52, 0.9, 0.8)
@export var outline_width: float = 2.0
@export var use_facing_colors: bool = false
@export var front_only: bool = false

var _active: bool = false
var _facing_sign: float = 1.0


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


func set_facing_direction(direction: float) -> void:
	if is_zero_approx(direction):
		return
	_facing_sign = signf(direction)
	if _active:
		queue_redraw()


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var rect := Rect2(-outline_size * 0.5, outline_size)
	if front_only:
		_draw_half_outline(rect, _facing_sign > 0.0, outline_color)
		return
	if use_facing_colors:
		_draw_half_outline(rect, _facing_sign < 0.0, back_outline_color)
		_draw_half_outline(rect, _facing_sign > 0.0, front_outline_color)
		return
	draw_rect(rect, outline_color, false, outline_width)


func _draw_half_outline(rect: Rect2, draw_right_half: bool, color: Color) -> void:
	var min_x := rect.position.x
	var max_x := rect.position.x + rect.size.x
	var mid_x := rect.position.x + rect.size.x * 0.5
	var top_y := rect.position.y
	var bottom_y := rect.position.y + rect.size.y
	if draw_right_half:
		draw_line(Vector2(mid_x, top_y), Vector2(max_x, top_y), color, outline_width)
		draw_line(Vector2(max_x, top_y), Vector2(max_x, bottom_y), color, outline_width)
		draw_line(Vector2(max_x, bottom_y), Vector2(mid_x, bottom_y), color, outline_width)
		draw_line(Vector2(mid_x, top_y), Vector2(mid_x, bottom_y), color, outline_width)
		return
	draw_line(Vector2(min_x, top_y), Vector2(mid_x, top_y), color, outline_width)
	draw_line(Vector2(min_x, top_y), Vector2(min_x, bottom_y), color, outline_width)
	draw_line(Vector2(min_x, bottom_y), Vector2(mid_x, bottom_y), color, outline_width)
	draw_line(Vector2(mid_x, top_y), Vector2(mid_x, bottom_y), color, outline_width)
