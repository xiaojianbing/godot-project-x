class_name GrapplePoint
extends Node2D


@export var enabled: bool = true


func _ready() -> void:
	add_to_group("grapple_points")


func can_grapple() -> bool:
	return enabled
