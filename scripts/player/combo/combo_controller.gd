class_name ComboController
extends RefCounted


const COMBO_RUNTIME_STATE_SCRIPT := preload("res://scripts/player/combo/combo_runtime_state.gd")

const KNOCKDOWN_CHAIN_ID := &"knockdown_string"
const KNOCKDOWN_LIGHT_1_STEP_ID := &"knockdown_light_1"
const KNOCKDOWN_LIGHT_2_STEP_ID := &"knockdown_light_2"
const KNOCKDOWN_FINISHER_STEP_ID := &"knockdown_heavy_finisher"
const KNOCKDOWN_FOLLOWUP_WINDOW := 0.32

const LAUNCHER_CHAIN_ID := &"launcher_gun_dump_string"
const LAUNCHER_LIGHT_3_STEP_ID := &"launcher_light_3"
const LAUNCHER_HEAVY_STEP_ID := &"launcher_heavy"
const LAUNCHER_SHOOT_1_STEP_ID := &"launcher_shoot_1"
const LAUNCHER_SHOOT_2_STEP_ID := &"launcher_shoot_2"
const LAUNCHER_RELOAD_STEP_ID := &"launcher_reload"
const LAUNCHER_FOLLOWUP_WINDOW := 0.34
const LAUNCHER_SHOOT_WINDOW := 0.56
const LAUNCHER_RELOAD_DURATION := 0.72
const AIR_CHASE_CHAIN_ID := &"air_chase_grapple_string"
const AIR_LIGHT_1_STEP_ID := &"air_light_1"
const AIR_LIGHT_2_STEP_ID := &"air_light_2"
const AIR_LIGHT_3_STEP_ID := &"air_light_3"
const AIR_HEAVY_STEP_ID := &"air_heavy_chase"
const AIR_FOLLOWUP_WINDOW := 0.3
const AIR_GRAPPLE_WINDOW := 0.4


var actor: Node = null
var runtime_state: RefCounted = COMBO_RUNTIME_STATE_SCRIPT.new()
var _followup_window_remaining: float = 0.0
var _reload_remaining: float = 0.0
var _pending_combo_shoot_step: StringName = &""


func setup(owner_actor: Node) -> void:
	actor = owner_actor
	runtime_state.reset()


func reset_runtime_state() -> void:
	runtime_state.reset()
	_followup_window_remaining = 0.0
	_reload_remaining = 0.0
	_pending_combo_shoot_step = &""


func update(delta: float) -> void:
	if _followup_window_remaining > 0.0:
		_followup_window_remaining = maxf(0.0, _followup_window_remaining - delta)
	if _reload_remaining > 0.0:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
	_sync_followup_window_state()
	_sync_reload_state()
	if _reload_remaining <= 0.0 and runtime_state.current_step_id == LAUNCHER_RELOAD_STEP_ID:
		_clear_chain_progress()
	if _followup_window_remaining > 0.0:
		return
	if runtime_state.current_chain_id == &"":
		return
	if runtime_state.awaiting_followup_input:
		_clear_chain_progress()


func resolve_light_action() -> StringName:
	if not _is_actor_grounded():
		if runtime_state.current_chain_id == AIR_CHASE_CHAIN_ID and runtime_state.followup_window_open and runtime_state.current_step_id == AIR_LIGHT_1_STEP_ID:
			runtime_state.current_step_id = AIR_LIGHT_2_STEP_ID
			runtime_state.awaiting_followup_input = false
			_close_followup_window()
			return &"attack_air_light_2"
		if _can_resolve_air_light_3():
			runtime_state.current_chain_id = AIR_CHASE_CHAIN_ID
			runtime_state.current_step_id = AIR_LIGHT_3_STEP_ID
			runtime_state.awaiting_followup_input = false
			_close_followup_window()
			return &"attack_air_light_3"
		_start_air_chain()
		return &"attack_air_light"
	if _can_resolve_launcher_light_3():
		runtime_state.current_chain_id = LAUNCHER_CHAIN_ID
		runtime_state.current_step_id = LAUNCHER_LIGHT_3_STEP_ID
		runtime_state.awaiting_followup_input = false
		_close_followup_window()
		return &"attack_light_3"
	if runtime_state.current_chain_id == KNOCKDOWN_CHAIN_ID and runtime_state.followup_window_open and runtime_state.current_step_id == KNOCKDOWN_LIGHT_1_STEP_ID:
		runtime_state.current_step_id = KNOCKDOWN_LIGHT_2_STEP_ID
		runtime_state.awaiting_followup_input = false
		_close_followup_window()
		return &"attack_light_2"
	_start_knockdown_chain()
	return &"attack_light"


func resolve_heavy_action() -> StringName:
	if _can_resolve_air_chase_heavy():
		runtime_state.current_chain_id = AIR_CHASE_CHAIN_ID
		runtime_state.current_step_id = AIR_HEAVY_STEP_ID
		runtime_state.awaiting_followup_input = false
		runtime_state.in_finisher_branch = true
		runtime_state.resolved_heavy_action_tag = &"attack_air_heavy_chase"
		runtime_state.hit_confirm_satisfied = false
		_close_followup_window()
		return &"attack_air_heavy_chase"
	if _can_resolve_launcher_heavy():
		runtime_state.current_chain_id = LAUNCHER_CHAIN_ID
		runtime_state.current_step_id = LAUNCHER_HEAVY_STEP_ID
		runtime_state.awaiting_followup_input = false
		runtime_state.in_finisher_branch = true
		runtime_state.resolved_heavy_action_tag = &"attack_heavy_launcher"
		runtime_state.hit_confirm_satisfied = false
		_close_followup_window()
		return &"attack_heavy_launcher"
	if _can_resolve_knockdown_finisher():
		runtime_state.current_chain_id = KNOCKDOWN_CHAIN_ID
		runtime_state.current_step_id = KNOCKDOWN_FINISHER_STEP_ID
		runtime_state.awaiting_followup_input = false
		runtime_state.in_finisher_branch = true
		runtime_state.resolved_heavy_action_tag = &"attack_heavy_finisher"
		_close_followup_window()
		return &"attack_heavy_finisher"
	reset_runtime_state()
	return &"attack_heavy"


func begin_shoot_aim() -> StringName:
	if _reload_remaining > 0.0:
		runtime_state.resolved_shoot_action_tag = &"reload"
		return &""
	if _can_prepare_launcher_shoot(LAUNCHER_HEAVY_STEP_ID, LAUNCHER_SHOOT_1_STEP_ID):
		runtime_state.current_chain_id = LAUNCHER_CHAIN_ID
		runtime_state.current_step_id = LAUNCHER_SHOOT_1_STEP_ID
		runtime_state.combo_shot_count = 1
		runtime_state.hit_confirm_satisfied = false
		runtime_state.resolved_shoot_action_tag = &"shoot_combo_1"
		runtime_state.awaiting_followup_input = false
		_close_followup_window()
		_pending_combo_shoot_step = &""
		return &"shoot_combo_1"
	if _can_prepare_launcher_shoot(LAUNCHER_SHOOT_1_STEP_ID, LAUNCHER_SHOOT_2_STEP_ID):
		runtime_state.current_chain_id = LAUNCHER_CHAIN_ID
		runtime_state.current_step_id = LAUNCHER_SHOOT_2_STEP_ID
		runtime_state.combo_shot_count = 2
		runtime_state.hit_confirm_satisfied = false
		runtime_state.resolved_shoot_action_tag = &"shoot_combo_2"
		runtime_state.awaiting_followup_input = false
		_close_followup_window()
		_pending_combo_shoot_step = &""
		return &"shoot_combo_2"
	if runtime_state.current_chain_id == LAUNCHER_CHAIN_ID and runtime_state.followup_window_open:
		_clear_chain_progress()
	_pending_combo_shoot_step = &""
	runtime_state.resolved_shoot_action_tag = &"shoot"
	return &"shoot_aim"


func can_begin_grapple_chase() -> bool:
	if runtime_state.current_chain_id != AIR_CHASE_CHAIN_ID:
		return false
	if runtime_state.current_step_id != AIR_HEAVY_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	if not runtime_state.hit_confirm_satisfied:
		return false
	return runtime_state.grapple_chase_target_available


func note_grapple_chase_started() -> void:
	runtime_state.last_resolved_action_tag = &"grapple_chase"
	_clear_chain_progress()


func resolve_shoot_release_action() -> StringName:
	runtime_state.resolved_shoot_action_tag = &"shoot"
	return &"shoot"


func note_action_started(action_tag: StringName) -> void:
	runtime_state.last_resolved_action_tag = action_tag
	if action_tag == &"attack_heavy" or action_tag == &"attack_heavy_finisher" or action_tag == &"attack_heavy_launcher":
		runtime_state.resolved_heavy_action_tag = action_tag
	if action_tag == &"attack_heavy_launcher":
		runtime_state.hit_confirm_satisfied = false
		runtime_state.last_target_reaction = &""
	if action_tag == &"shoot" or action_tag == &"shoot_combo_1" or action_tag == &"shoot_combo_2":
		runtime_state.queued_input_action = &"shoot"
		runtime_state.resolved_shoot_action_tag = action_tag
		if action_tag == &"shoot_combo_1" or action_tag == &"shoot_combo_2":
			runtime_state.hit_confirm_satisfied = false
			runtime_state.last_target_reaction = &""
	elif action_tag == &"attack_light" or action_tag == &"attack_light_2" or action_tag == &"attack_light_3":
		runtime_state.queued_input_action = &"attack_light"
		runtime_state.awaiting_followup_input = false
	elif action_tag == &"attack_air_light" or action_tag == &"attack_air_light_2" or action_tag == &"attack_air_light_3":
		runtime_state.queued_input_action = &"attack_light"
		runtime_state.awaiting_followup_input = false
	elif action_tag == &"attack_heavy" or action_tag == &"attack_heavy_finisher" or action_tag == &"attack_heavy_launcher":
		runtime_state.queued_input_action = &"attack_heavy"
		runtime_state.awaiting_followup_input = false
	elif action_tag == &"attack_air_heavy_chase":
		runtime_state.queued_input_action = &"attack_heavy"
		runtime_state.awaiting_followup_input = false
		runtime_state.hit_confirm_satisfied = false
		runtime_state.last_target_reaction = &""


func note_action_completed(action_tag: StringName) -> void:
	runtime_state.last_completed_step_id = action_tag
	match action_tag:
		&"attack_light":
			if runtime_state.current_chain_id == KNOCKDOWN_CHAIN_ID and runtime_state.current_step_id == KNOCKDOWN_LIGHT_1_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(KNOCKDOWN_FOLLOWUP_WINDOW)
		&"attack_light_2":
			if runtime_state.current_chain_id == KNOCKDOWN_CHAIN_ID and runtime_state.current_step_id == KNOCKDOWN_LIGHT_2_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(KNOCKDOWN_FOLLOWUP_WINDOW)
		&"attack_light_3":
			if runtime_state.current_chain_id == LAUNCHER_CHAIN_ID and runtime_state.current_step_id == LAUNCHER_LIGHT_3_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(LAUNCHER_FOLLOWUP_WINDOW)
		&"attack_air_light":
			if runtime_state.current_chain_id == AIR_CHASE_CHAIN_ID and runtime_state.current_step_id == AIR_LIGHT_1_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(AIR_FOLLOWUP_WINDOW)
		&"attack_air_light_2":
			if runtime_state.current_chain_id == AIR_CHASE_CHAIN_ID and runtime_state.current_step_id == AIR_LIGHT_2_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(AIR_FOLLOWUP_WINDOW)
		&"attack_air_light_3":
			if runtime_state.current_chain_id == AIR_CHASE_CHAIN_ID and runtime_state.current_step_id == AIR_LIGHT_3_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(AIR_FOLLOWUP_WINDOW)
		&"attack_air_heavy_chase":
			if runtime_state.current_chain_id == AIR_CHASE_CHAIN_ID and runtime_state.current_step_id == AIR_HEAVY_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(AIR_GRAPPLE_WINDOW)
		&"attack_heavy_launcher":
			if runtime_state.current_chain_id == LAUNCHER_CHAIN_ID and runtime_state.current_step_id == LAUNCHER_HEAVY_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(LAUNCHER_SHOOT_WINDOW)
		&"attack_heavy_finisher":
			_clear_chain_progress()
		&"attack_heavy":
			_clear_chain_progress()
		&"shoot_combo_1":
			if runtime_state.current_chain_id == LAUNCHER_CHAIN_ID and runtime_state.current_step_id == LAUNCHER_SHOOT_1_STEP_ID:
				runtime_state.awaiting_followup_input = true
				_open_followup_window(LAUNCHER_SHOOT_WINDOW)
		&"shoot_combo_2":
			if runtime_state.current_chain_id == LAUNCHER_CHAIN_ID and runtime_state.current_step_id == LAUNCHER_SHOOT_2_STEP_ID:
				_start_reload_state()
		&"shoot":
			if runtime_state.current_chain_id != LAUNCHER_CHAIN_ID:
				_clear_chain_progress()


func note_hit_confirm_satisfied() -> void:
	runtime_state.hit_confirm_satisfied = true


func note_target_reaction(reaction_tag: StringName) -> void:
	runtime_state.last_target_reaction = reaction_tag


func set_followup_window_active(active: bool) -> void:
	if active:
		_open_followup_window(KNOCKDOWN_FOLLOWUP_WINDOW)
	else:
		_close_followup_window()


func set_finisher_branch_active(active: bool) -> void:
	runtime_state.in_finisher_branch = active


func set_reload_state_active(active: bool) -> void:
	if active:
		_start_reload_state()
		return
	_reload_remaining = 0.0
	runtime_state.in_reload_state = false
	runtime_state.reload_remaining = 0.0


func set_grapple_chase_target_available(active: bool) -> void:
	runtime_state.grapple_chase_target_available = active


func get_runtime_state() -> RefCounted:
	return runtime_state


func _is_actor_grounded() -> bool:
	return actor != null and actor.has_method("is_on_floor") and bool(actor.call("is_on_floor"))


func _can_resolve_knockdown_finisher() -> bool:
	if not _is_actor_grounded():
		return false
	if runtime_state.current_chain_id != KNOCKDOWN_CHAIN_ID:
		return false
	if runtime_state.current_step_id != KNOCKDOWN_LIGHT_2_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	return runtime_state.hit_confirm_satisfied


func _can_resolve_launcher_light_3() -> bool:
	if not _is_actor_grounded():
		return false
	if runtime_state.current_chain_id != KNOCKDOWN_CHAIN_ID:
		return false
	if runtime_state.current_step_id != KNOCKDOWN_LIGHT_2_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	return runtime_state.hit_confirm_satisfied


func _can_resolve_air_light_3() -> bool:
	if _is_actor_grounded():
		return false
	if runtime_state.current_chain_id != AIR_CHASE_CHAIN_ID:
		return false
	if runtime_state.current_step_id != AIR_LIGHT_2_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	return runtime_state.hit_confirm_satisfied


func _can_resolve_air_chase_heavy() -> bool:
	if _is_actor_grounded():
		return false
	if runtime_state.current_chain_id != AIR_CHASE_CHAIN_ID:
		return false
	if runtime_state.current_step_id != AIR_LIGHT_3_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	return runtime_state.hit_confirm_satisfied


func _can_resolve_launcher_heavy() -> bool:
	if not _is_actor_grounded():
		return false
	if runtime_state.current_chain_id != LAUNCHER_CHAIN_ID:
		return false
	if runtime_state.current_step_id != LAUNCHER_LIGHT_3_STEP_ID:
		return false
	if not runtime_state.followup_window_open:
		return false
	return runtime_state.hit_confirm_satisfied


func _can_prepare_launcher_shoot(required_step: StringName, next_step: StringName) -> bool:
	if runtime_state.current_chain_id != LAUNCHER_CHAIN_ID:
		return false
	if runtime_state.current_step_id != required_step:
		return false
	if not runtime_state.followup_window_open:
		return false
	if not runtime_state.hit_confirm_satisfied:
		return false
	if next_step == LAUNCHER_SHOOT_2_STEP_ID and runtime_state.combo_shot_count < 1:
		return false
	return true


func _start_knockdown_chain() -> void:
	runtime_state.current_chain_id = KNOCKDOWN_CHAIN_ID
	runtime_state.current_step_id = KNOCKDOWN_LIGHT_1_STEP_ID
	runtime_state.hit_confirm_satisfied = false
	runtime_state.awaiting_followup_input = false
	runtime_state.in_finisher_branch = false
	runtime_state.combo_shot_count = 0
	runtime_state.last_target_reaction = &""
	_close_followup_window()


func _start_air_chain() -> void:
	runtime_state.current_chain_id = AIR_CHASE_CHAIN_ID
	runtime_state.current_step_id = AIR_LIGHT_1_STEP_ID
	runtime_state.hit_confirm_satisfied = false
	runtime_state.awaiting_followup_input = false
	runtime_state.in_finisher_branch = false
	runtime_state.combo_shot_count = 0
	runtime_state.last_target_reaction = &""
	_close_followup_window()


func _open_followup_window(duration: float) -> void:
	_followup_window_remaining = maxf(duration, 0.0)
	_sync_followup_window_state()


func _close_followup_window() -> void:
	_followup_window_remaining = 0.0
	_sync_followup_window_state()


func _sync_followup_window_state() -> void:
	runtime_state.followup_window_remaining = _followup_window_remaining
	runtime_state.followup_window_open = _followup_window_remaining > 0.0


func _sync_reload_state() -> void:
	runtime_state.reload_remaining = _reload_remaining
	runtime_state.in_reload_state = _reload_remaining > 0.0


func _start_reload_state() -> void:
	_pending_combo_shoot_step = &""
	_followup_window_remaining = 0.0
	runtime_state.current_chain_id = LAUNCHER_CHAIN_ID
	runtime_state.current_step_id = LAUNCHER_RELOAD_STEP_ID
	runtime_state.awaiting_followup_input = false
	runtime_state.in_finisher_branch = false
	runtime_state.combo_shot_count = 0
	_reload_remaining = LAUNCHER_RELOAD_DURATION
	_sync_followup_window_state()
	_sync_reload_state()


func _clear_chain_progress() -> void:
	runtime_state.current_chain_id = &""
	runtime_state.current_step_id = &""
	runtime_state.queued_input_action = &""
	runtime_state.hit_confirm_satisfied = false
	runtime_state.awaiting_followup_input = false
	runtime_state.in_finisher_branch = false
	runtime_state.in_reload_state = false
	runtime_state.reload_remaining = 0.0
	runtime_state.combo_shot_count = 0
	_pending_combo_shoot_step = &""
	_reload_remaining = 0.0
	_close_followup_window()
