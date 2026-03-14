class_name CharacterSignals
extends RefCounted


signal invincibility_changed(is_invincible: bool)
signal input_acceptance_changed(can_accept_input: bool)
signal action_tag_changed(action_tag: StringName)


var is_grounded: bool = false
var is_invincible: bool = false:
	set(value):
		if is_invincible == value:
			return
		is_invincible = value
		invincibility_changed.emit(is_invincible)

var has_super_armor: bool = false
var can_accept_input: bool = true:
	set(value):
		if can_accept_input == value:
			return
		can_accept_input = value
		input_acceptance_changed.emit(can_accept_input)

var is_dead: bool = false
var facing_direction: int = 1
var current_action_tag: StringName = &"idle":
	set(value):
		if current_action_tag == value:
			return
		current_action_tag = value
		action_tag_changed.emit(current_action_tag)


func reset_runtime_flags() -> void:
	is_grounded = false
	is_invincible = false
	has_super_armor = false
	can_accept_input = true
	is_dead = false
	facing_direction = 1
	current_action_tag = &"idle"
