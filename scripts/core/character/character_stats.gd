class_name CharacterStats
extends RefCounted


signal hp_changed(previous_hp: float, current_hp: float)
signal energy_changed(previous_energy: float, current_energy: float)
signal damaged(hit_data: Variant, damage_result: DamageResult)
signal healed(amount: float, current_hp: float)
signal died(damage_result: DamageResult)
signal buff_added(buff_id: StringName)
signal buff_removed(buff_id: StringName)


var max_hp: float = 100.0
var current_hp: float = 100.0
var max_energy: float = 100.0
var current_energy: float = 0.0
var attack_power: float = 10.0
var defense_ratio: float = 1.0
var poise: float = 0.0
var stun_resistance: float = 0.0
var move_speed_scale: float = 1.0
var dash_scale: float = 1.0
var air_control_scale: float = 1.0

var _buffs: Dictionary = {}


func configure_from_profile(combat_profile: CharacterCombatProfile) -> void:
	if combat_profile == null:
		push_warning("CharacterStats received a null combat profile.")
		return
	max_hp = combat_profile.base_max_hp
	current_hp = max_hp
	max_energy = combat_profile.base_max_energy
	current_energy = clampf(combat_profile.starting_energy, 0.0, max_energy)
	attack_power = combat_profile.base_attack_power
	defense_ratio = combat_profile.base_defense_ratio
	poise = combat_profile.base_poise
	stun_resistance = combat_profile.base_stun_resistance


func apply_damage(hit_data: Variant, signals: CharacterSignals = null) -> DamageResult:
	var result := DamageResult.new()
	result.previous_hp = current_hp
	result.current_hp = current_hp
	if signals != null and signals.is_invincible:
		result.was_blocked_by_invincible = true
		damaged.emit(hit_data, result)
		return result
	if signals != null and signals.has_super_armor:
		result.triggered_super_armor = true
	var incoming_damage: float = _extract_damage_value(hit_data)
	var final_damage := maxf(0.0, incoming_damage * maxf(defense_ratio, 0.0))
	if final_damage <= 0.0:
		damaged.emit(hit_data, result)
		return result
	current_hp = clampf(current_hp - final_damage, 0.0, max_hp)
	result.applied = true
	result.damage_applied = final_damage
	result.current_hp = current_hp
	result.became_zero = is_zero_approx(current_hp)
	hp_changed.emit(result.previous_hp, current_hp)
	damaged.emit(hit_data, result)
	if result.became_zero:
		died.emit(result)
	return result


func heal(amount: float) -> HealResult:
	var result := HealResult.new()
	result.previous_hp = current_hp
	if amount <= 0.0 or current_hp >= max_hp:
		result.current_hp = current_hp
		return result
	current_hp = clampf(current_hp + amount, 0.0, max_hp)
	result.applied = true
	result.current_hp = current_hp
	result.amount_applied = current_hp - result.previous_hp
	hp_changed.emit(result.previous_hp, current_hp)
	healed.emit(result.amount_applied, current_hp)
	return result


func add_energy(amount: float) -> EnergyChangeResult:
	return _change_energy(amount)


func spend_energy(amount: float) -> EnergyChangeResult:
	return _change_energy(-absf(amount))


func add_buff(buff_id: StringName, buff_data: Variant = null) -> void:
	_buffs[buff_id] = buff_data
	buff_added.emit(buff_id)


func remove_buff(buff_id: StringName) -> void:
	if not _buffs.erase(buff_id):
		return
	buff_removed.emit(buff_id)


func has_buff(buff_id: StringName) -> bool:
	return _buffs.has(buff_id)


func get_stats_view() -> CharacterStatsView:
	var view := CharacterStatsView.new()
	view.current_hp = current_hp
	view.max_hp = max_hp
	view.current_energy = current_energy
	view.max_energy = max_energy
	view.is_dead = is_zero_approx(current_hp)
	return view


func _change_energy(delta_amount: float) -> EnergyChangeResult:
	var result := EnergyChangeResult.new()
	result.previous_energy = current_energy
	if is_zero_approx(delta_amount):
		result.current_energy = current_energy
		return result
	current_energy = clampf(current_energy + delta_amount, 0.0, max_energy)
	result.applied = not is_equal_approx(result.previous_energy, current_energy)
	result.current_energy = current_energy
	result.amount_applied = current_energy - result.previous_energy
	if result.applied:
		energy_changed.emit(result.previous_energy, current_energy)
	return result


func _extract_damage_value(hit_data: Variant) -> float:
	if hit_data is Dictionary:
		return float(hit_data.get("damage", 0.0))
	if hit_data is float or hit_data is int:
		return float(hit_data)
	return 0.0
