class_name CharacterContext
extends RefCounted


var body: Node = null
var stats: CharacterStats = null
var signals: CharacterSignals = null
var combat_profile: CharacterCombatProfile = null
var motion_profile: CharacterMotionProfile = null
var animation_bridge: Node = null


func setup(
	owner_body: Node,
	owner_stats: CharacterStats,
	owner_signals: CharacterSignals,
	owner_combat_profile: CharacterCombatProfile,
	owner_motion_profile: CharacterMotionProfile,
	owner_animation_bridge: Node = null
) -> void:
	body = owner_body
	stats = owner_stats
	signals = owner_signals
	combat_profile = owner_combat_profile
	motion_profile = owner_motion_profile
	animation_bridge = owner_animation_bridge


func set_facing_direction(direction: int) -> void:
	if signals == null:
		return
	if direction == 0:
		return
	signals.facing_direction = 1 if direction > 0 else -1


func set_input_enabled(enabled: bool) -> void:
	if signals == null:
		return
	signals.can_accept_input = enabled


func reset_runtime_state() -> void:
	if signals != null:
		signals.reset_runtime_flags()
