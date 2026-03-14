class_name StateMachineDriver
extends RefCounted


var current_state_id: StringName = &""

var _states: Dictionary = {}
var _current_state: StateNode = null


func register_state(state_id: StringName, state: StateNode) -> void:
	if state_id == StringName():
		push_warning("StateMachineDriver received an empty state id.")
		return
	if state == null:
		push_warning("StateMachineDriver tried to register a null state.")
		return
	_states[state_id] = state


func request_transition(next_state_id: StringName, context: Variant = null) -> bool:
	var next_state: StateNode = _states.get(next_state_id)
	if next_state == null:
		push_warning("StateMachineDriver could not find requested state: %s" % String(next_state_id))
		return false
	if _current_state != null:
		_current_state.exit(context)
	_current_state = next_state
	current_state_id = next_state_id
	_current_state.enter(context)
	return true


func update_physics(context: Variant, delta: float) -> void:
	if _current_state == null:
		return
	_current_state.physics_update(context, delta)


func dispatch_input(context: Variant, input_data: Variant) -> void:
	if _current_state == null:
		return
	_current_state.handle_input(context, input_data)


func has_state(state_id: StringName) -> bool:
	return _states.has(state_id)
