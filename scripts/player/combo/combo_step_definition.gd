class_name ComboStepDefinition
extends Resource


@export var step_id: StringName = &""
@export var input_action: StringName = &""
@export var action_tag: StringName = &""
@export var requires_hit_confirm: bool = false
@export var allowed_state_tags: Array[StringName] = []
@export var followup_window_open: float = 0.0
@export var followup_window_close: float = 0.0
@export var next_step_ids: Array[StringName] = []
@export var branch_type: StringName = &""
