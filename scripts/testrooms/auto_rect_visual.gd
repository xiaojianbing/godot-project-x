@tool
class_name AutoRectVisual
extends Polygon2D


@export var collision_shape_path: NodePath = NodePath("../CollisionShape2D"):
	set(value):
		collision_shape_path = value
		_update_from_collision_shape()


func _enter_tree() -> void:
	set_process(true)
	_update_from_collision_shape()


func _ready() -> void:
	set_process(true)
	_update_from_collision_shape()


func _process(_delta: float) -> void:
	_update_from_collision_shape()


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
		_update_from_collision_shape()


func _update_from_collision_shape() -> void:
	var collision_shape := get_node_or_null(collision_shape_path) as CollisionShape2D
	if collision_shape == null:
		return
	var rect_shape := collision_shape.shape as RectangleShape2D
	if rect_shape == null:
		return
	position = collision_shape.position
	rotation = collision_shape.rotation
	scale = Vector2.ONE
	var half_size := rect_shape.size * 0.5
	polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
