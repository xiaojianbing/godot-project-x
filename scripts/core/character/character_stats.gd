class_name CharacterStats
extends RefCounted


const CHARACTER_ATTRIBUTES_PROFILE_SCRIPT := preload("res://resources/characters/character_attributes_profile.gd")
const CHARACTER_ATTRIBUTE_SET_SCRIPT := preload("res://scripts/core/character/data/character_attribute_set.gd")


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
var knockback_resistance: float = 0.0
var move_speed_scale: float = 1.0
var dash_scale: float = 1.0
var air_control_scale: float = 1.0
var attribute_set: RefCounted = null

var _buffs: Dictionary = {}


func configure_from_profile(combat_profile: CharacterCombatProfile) -> void:
	if combat_profile == null:
		push_warning("CharacterStats received a null combat profile.")
		return
	var legacy_attributes_profile := CHARACTER_ATTRIBUTES_PROFILE_SCRIPT.new()
	configure_from_attributes_profile(legacy_attributes_profile, false)


func configure_from_attributes_profile(attributes_profile: Resource, preserve_current_resources: bool = false) -> void:
	if attributes_profile == null:
		push_warning("CharacterStats received a null attributes profile.")
		return
	var next_attribute_set := CHARACTER_ATTRIBUTE_SET_SCRIPT.new()
	next_attribute_set.set_profile(attributes_profile)
	configure_from_attribute_set(next_attribute_set, preserve_current_resources)


func configure_from_attribute_set(next_attribute_set: RefCounted, preserve_current_resources: bool = false) -> void:
	if next_attribute_set == null:
		push_warning("CharacterStats received a null attribute set.")
		return
	attribute_set = next_attribute_set
	_refresh_from_attribute_set(preserve_current_resources)


func refresh_from_attribute_set(preserve_current_resources: bool = true) -> void:
	_refresh_from_attribute_set(preserve_current_resources)


func initialize_resource_values() -> void:
	if attribute_set == null:
		current_hp = max_hp
		current_energy = 0.0
		return
	current_hp = _resolve_initial_value(_get_attribute_float(&"starting_hp", -1.0), max_hp)
	current_energy = _resolve_initial_value(_get_attribute_float(&"starting_energy", 0.0), max_energy)


func apply_respawn_resource_values() -> void:
	if attribute_set == null:
		current_hp = max_hp
		current_energy = 0.0
		return
	current_hp = _resolve_respawn_value(
		_get_attribute_mode(&"respawn_hp_mode", &"full"),
		_get_attribute_float(&"respawn_hp_value", 1.0),
		_get_attribute_float(&"starting_hp", -1.0),
		max_hp
	)
	current_energy = _resolve_respawn_value(
		_get_attribute_mode(&"respawn_energy_mode", &"starting"),
		_get_attribute_float(&"respawn_energy_value", 0.0),
		_get_attribute_float(&"starting_energy", 0.0),
		max_energy
	)


func get_attribute_value(attribute_id: StringName, fallback_value: float = 0.0) -> float:
	if attribute_set != null:
		return attribute_set.get_value(attribute_id)
	match attribute_id:
		&"max_hp":
			return max_hp
		&"max_energy":
			return max_energy
		&"starting_hp":
			return max_hp
		&"starting_energy":
			return 0.0
		&"attack_power":
			return attack_power
		&"defense_ratio":
			return defense_ratio
		&"poise":
			return poise
		&"stun_resistance":
			return stun_resistance
		&"knockback_resistance":
			return knockback_resistance
		&"move_speed_scale":
			return move_speed_scale
		&"dash_scale":
			return dash_scale
		&"air_control_scale":
			return air_control_scale
		_:
			return fallback_value


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
	_apply_buff_attribute_modifiers(buff_id, buff_data)
	buff_added.emit(buff_id)


func remove_buff(buff_id: StringName) -> void:
	if not _buffs.has(buff_id):
		return
	_remove_buff_attribute_modifiers(buff_id)
	_buffs.erase(buff_id)
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


func _refresh_from_attribute_set(preserve_current_resources: bool) -> void:
	if attribute_set == null:
		push_warning("CharacterStats tried to refresh without an attribute set.")
		return
	var next_max_hp: float = attribute_set.get_value(&"max_hp")
	var next_max_energy: float = attribute_set.get_value(&"max_energy")
	var next_starting_hp: float = attribute_set.get_value(&"starting_hp")
	var next_starting_energy: float = attribute_set.get_value(&"starting_energy")
	max_hp = next_max_hp
	max_energy = next_max_energy
	attack_power = attribute_set.get_value(&"attack_power")
	defense_ratio = attribute_set.get_value(&"defense_ratio")
	poise = attribute_set.get_value(&"poise")
	stun_resistance = attribute_set.get_value(&"stun_resistance")
	knockback_resistance = attribute_set.get_value(&"knockback_resistance")
	move_speed_scale = attribute_set.get_value(&"move_speed_scale")
	dash_scale = attribute_set.get_value(&"dash_scale")
	air_control_scale = attribute_set.get_value(&"air_control_scale")
	if preserve_current_resources:
		current_hp = clampf(current_hp, 0.0, max_hp)
		current_energy = clampf(current_energy, 0.0, max_energy)
		return
	current_hp = _resolve_initial_value(next_starting_hp, max_hp)
	current_energy = _resolve_initial_value(next_starting_energy, max_energy)


func _apply_buff_attribute_modifiers(buff_id: StringName, buff_data: Variant) -> void:
	if attribute_set == null:
		return
	_remove_buff_attribute_modifiers(buff_id)
	if buff_data is RefCounted and buff_data.has_method("get"):
		var modifier: Variant = buff_data
		modifier.source_id = buff_id
		attribute_set.add_modifier(modifier)
		refresh_from_attribute_set(true)
		return
	if buff_data is Array:
		for entry in buff_data:
			if entry is RefCounted and entry.has_method("get"):
				entry.source_id = buff_id
				attribute_set.add_modifier(entry)
		refresh_from_attribute_set(true)


func _remove_buff_attribute_modifiers(buff_id: StringName) -> void:
	if attribute_set == null:
		return
	attribute_set.remove_modifiers_by_source(buff_id)
	refresh_from_attribute_set(true)


func _get_attribute_float(attribute_id: StringName, fallback_value: float) -> float:
	if attribute_set == null:
		return fallback_value
	return attribute_set.get_value(attribute_id)


func _get_attribute_mode(attribute_id: StringName, fallback_value: StringName) -> StringName:
	if attribute_set == null:
		return fallback_value
	return attribute_set.get_string_value(attribute_id, fallback_value)


func _resolve_initial_value(configured_value: float, max_value: float) -> float:
	if configured_value < 0.0:
		return max_value
	return clampf(configured_value, 0.0, max_value)


func _resolve_respawn_value(mode: StringName, mode_value: float, starting_value: float, max_value: float) -> float:
	match mode:
		&"starting":
			return _resolve_initial_value(starting_value, max_value)
		&"ratio":
			return clampf(max_value * mode_value, 0.0, max_value)
		&"fixed":
			return clampf(mode_value, 0.0, max_value)
		_:
			return max_value
