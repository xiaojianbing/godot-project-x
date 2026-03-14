extends Node


signal event_emitted(channel: StringName, payload: Variant)


var _listeners: Dictionary = {}


func emit_event(channel: StringName, payload: Variant = null) -> void:
	event_emitted.emit(channel, payload)
	var listeners: Array = _listeners.get(channel, [])
	for listener: Callable in listeners:
		if listener.is_valid():
			listener.call(payload)


func subscribe(channel: StringName, listener: Callable) -> void:
	if not listener.is_valid():
		push_warning("EventHub tried to subscribe an invalid listener.")
		return
	var listeners: Array = _listeners.get(channel, [])
	if listeners.has(listener):
		return
	listeners.append(listener)
	_listeners[channel] = listeners


func unsubscribe(channel: StringName, listener: Callable) -> void:
	if not _listeners.has(channel):
		return
	var listeners: Array = _listeners[channel]
	listeners.erase(listener)
	if listeners.is_empty():
		_listeners.erase(channel)
	else:
		_listeners[channel] = listeners
