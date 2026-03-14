class_name DamageResult
extends RefCounted


var applied: bool = false
var previous_hp: float = 0.0
var current_hp: float = 0.0
var damage_applied: float = 0.0
var became_zero: bool = false
var was_blocked_by_invincible: bool = false
var triggered_super_armor: bool = false


func duplicate_result() -> DamageResult:
	var result := DamageResult.new()
	result.applied = applied
	result.previous_hp = previous_hp
	result.current_hp = current_hp
	result.damage_applied = damage_applied
	result.became_zero = became_zero
	result.was_blocked_by_invincible = was_blocked_by_invincible
	result.triggered_super_armor = triggered_super_armor
	return result
