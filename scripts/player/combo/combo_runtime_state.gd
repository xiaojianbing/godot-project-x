class_name ComboRuntimeState
extends RefCounted


var current_chain_id: StringName = &""
var current_step_id: StringName = &""
var queued_input_action: StringName = &""
var last_completed_step_id: StringName = &""
var last_resolved_action_tag: StringName = &""
var followup_window_open: bool = false
var followup_window_remaining: float = 0.0
var awaiting_followup_input: bool = false
var hit_confirm_satisfied: bool = false
var in_finisher_branch: bool = false
var in_reload_state: bool = false
var reload_remaining: float = 0.0
var grapple_chase_target_available: bool = false
var resolved_heavy_action_tag: StringName = &"attack_heavy"
var resolved_shoot_action_tag: StringName = &"shoot"
var combo_shot_count: int = 0
var last_target_reaction: StringName = &""


func reset() -> void:
	current_chain_id = &""
	current_step_id = &""
	queued_input_action = &""
	last_completed_step_id = &""
	last_resolved_action_tag = &""
	followup_window_open = false
	followup_window_remaining = 0.0
	awaiting_followup_input = false
	hit_confirm_satisfied = false
	in_finisher_branch = false
	in_reload_state = false
	reload_remaining = 0.0
	grapple_chase_target_available = false
	resolved_heavy_action_tag = &"attack_heavy"
	resolved_shoot_action_tag = &"shoot"
	combo_shot_count = 0
	last_target_reaction = &""


func is_combo_active() -> bool:
	return current_chain_id != &"" or current_step_id != &""
