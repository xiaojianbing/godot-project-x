class_name DamageReceiver
extends RefCounted


signal hurt_requested(hit_data: Variant, damage_result: DamageResult)
signal super_armor_hit(hit_data: Variant, damage_result: DamageResult)
signal death_requested(damage_result: DamageResult)


var context: CharacterContext = null


func setup(owner_context: CharacterContext) -> void:
	context = owner_context


func receive_hit(hit_data: Variant) -> DamageResult:
	var result := DamageResult.new()
	if context == null or context.stats == null:
		push_warning("DamageReceiver was used without a valid CharacterContext.")
		return result
	result = context.stats.apply_damage(hit_data, context.signals)
	if result.was_blocked_by_invincible:
		return result
	if result.triggered_super_armor:
		super_armor_hit.emit(hit_data, result)
	if result.applied and not result.became_zero:
		hurt_requested.emit(hit_data, result)
	if result.became_zero:
		if context.signals != null:
			context.signals.is_dead = true
			context.signals.can_accept_input = false
			context.signals.current_action_tag = &"death"
		death_requested.emit(result)
	return result
