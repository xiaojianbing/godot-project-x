class_name DashAfterimage
extends Polygon2D


@export var fade_duration: float = 0.14

var _remaining: float = 0.14


func _ready() -> void:
	_remaining = fade_duration


func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	var alpha_ratio := _remaining / maxf(fade_duration, 0.001)
	color.a = alpha_ratio * 0.55
	if _remaining <= 0.0:
		queue_free()
