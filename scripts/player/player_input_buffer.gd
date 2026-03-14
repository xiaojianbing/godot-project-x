class_name PlayerInputBuffer
extends RefCounted


var _jump_buffer_remaining: float = 0.0
var _dash_buffer_remaining: float = 0.0
var _grapple_buffer_remaining: float = 0.0


func update(delta: float) -> void:
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	_dash_buffer_remaining = maxf(0.0, _dash_buffer_remaining - delta)
	_grapple_buffer_remaining = maxf(0.0, _grapple_buffer_remaining - delta)


func buffer_jump(buffer_time: float) -> void:
	_jump_buffer_remaining = maxf(_jump_buffer_remaining, buffer_time)


func buffer_dash(buffer_time: float) -> void:
	_dash_buffer_remaining = maxf(_dash_buffer_remaining, buffer_time)


func buffer_grapple(buffer_time: float) -> void:
	_grapple_buffer_remaining = maxf(_grapple_buffer_remaining, buffer_time)


func has_buffered_jump() -> bool:
	return _jump_buffer_remaining > 0.0


func has_buffered_dash() -> bool:
	return _dash_buffer_remaining > 0.0


func has_buffered_grapple() -> bool:
	return _grapple_buffer_remaining > 0.0


func consume_jump() -> bool:
	if not has_buffered_jump():
		return false
	_jump_buffer_remaining = 0.0
	return true


func consume_dash() -> bool:
	if not has_buffered_dash():
		return false
	_dash_buffer_remaining = 0.0
	return true


func consume_grapple() -> bool:
	if not has_buffered_grapple():
		return false
	_grapple_buffer_remaining = 0.0
	return true
