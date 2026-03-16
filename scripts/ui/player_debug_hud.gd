class_name PlayerDebugHud
extends CanvasLayer


@export var target_path: NodePath

@onready var _label: Label = $PanelContainer/MarginContainer/DebugLabel


func _process(_delta: float) -> void:
	var actor: Node = get_node_or_null(target_path)
	if actor == null:
		_label.text = "No player target"
		return
	if not actor is PlayerTestActor:
		_label.text = "Target is not PlayerTestActor"
		return
	var player_actor: PlayerTestActor = actor as PlayerTestActor
	var state_id: String = "n/a"
	var locomotion_state_machine: LocomotionStateMachine = player_actor.get_locomotion_state_machine()
	if locomotion_state_machine != null:
		state_id = String(locomotion_state_machine.get_current_state_id())
	var signals: CharacterSignals = player_actor.signals
	var stats: CharacterStats = player_actor.stats
	_label.text = "STATE: %s\nVEL: (%.1f, %.1f)\nFLOOR: %s\nWALL: %s\nLEDGE: %s\nGRAPPLE: %s\nSWIM: %s\nGUARD: %s\nPARRY_WIN: %.2f\nCROUCH: %s\nUNLOCKS: DJ=%s SW=%s GP=%s\nAIR_JUMPS: %d\nHP: %.1f / %.1f\nENERGY: %.1f / %.1f\nDASH: %.2f\nCOYOTE: %.2f" % [
		state_id,
		player_actor.velocity.x,
		player_actor.velocity.y,
		str(player_actor.is_on_floor()),
		str(player_actor.is_on_wall_only()),
		str(player_actor.is_edge_hanging()),
		str(player_actor.is_grappling()),
		str(player_actor.is_swimming()),
		str(player_actor.is_guarding()),
		player_actor.get_parry_window_remaining(),
		str(player_actor.is_crouching()),
		str(player_actor.double_jump_unlocked),
		str(player_actor.swim_unlocked),
		str(player_actor.grapple_unlocked),
		player_actor.get_air_jumps_remaining(),
		stats.current_hp if stats != null else 0.0,
		stats.max_hp if stats != null else 0.0,
		stats.current_energy if stats != null else 0.0,
		stats.max_energy if stats != null else 0.0,
		player_actor.get_dash_time_remaining(),
		player_actor.get_coyote_time_remaining(),
	]
	if signals != null:
		_label.text += "\nACTION: %s\nINVINCIBLE: %s" % [String(signals.current_action_tag), str(signals.is_invincible)]
	_label.text += "\nATTACK: %s\nCOMBAT: %s\nJUMP_FAIL: %s\nDASH_FAIL: %s\nSWIM_FAIL: %s\nGRAPPLE_FAIL: %s" % [player_actor.get_last_attack_action(), player_actor.get_last_combat_result(), player_actor.get_last_jump_failure_reason(), player_actor.get_last_dash_failure_reason(), player_actor.get_last_swim_failure_reason(), player_actor.get_last_grapple_failure_reason()]
	var combo_state: Variant = player_actor.get_combo_runtime_state()
	if combo_state != null:
		_label.text += "\nCOMBO: %s / %s\nFOLLOWUP: %s (%.2f)  HIT_OK: %s\nHEAVY: %s  SHOOT: %s\nREACTION: %s  SHOTS: %d\nRELOAD: %s (%.2f)  CHASE: %s" % [
			String(combo_state.current_chain_id),
			String(combo_state.current_step_id),
			str(combo_state.followup_window_open),
			combo_state.followup_window_remaining,
			str(combo_state.hit_confirm_satisfied),
			String(combo_state.resolved_heavy_action_tag),
			String(combo_state.resolved_shoot_action_tag),
			String(combo_state.last_target_reaction),
			combo_state.combo_shot_count,
			str(combo_state.in_reload_state),
			combo_state.reload_remaining,
			str(combo_state.grapple_chase_target_available),
		]
