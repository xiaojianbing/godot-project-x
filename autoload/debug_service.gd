extends Node


@export var debug_enabled: bool = true


func log_info(channel: StringName, message: String) -> void:
	if not debug_enabled:
		return
	print("[INFO][%s] %s" % [String(channel), message])


func log_warning(channel: StringName, message: String) -> void:
	if not debug_enabled:
		return
	push_warning("[%s] %s" % [String(channel), message])


func log_error(channel: StringName, message: String) -> void:
	push_error("[%s] %s" % [String(channel), message])
