class_name CharacterAttributeSet
extends RefCounted


signal attribute_changed(attribute_id: StringName, previous_value: float, current_value: float)
signal attributes_recalculated()
signal modifier_added(source_id: StringName, attribute_id: StringName)
signal modifier_removed(source_id: StringName, attribute_id: StringName)


const OP_FLAT_ADD := &"flat_add"
const OP_PERCENT_ADD := &"percent_add"
const OP_MULTIPLIER := &"multiplier"
const OP_OVERRIDE := &"override"


var profile: Resource = null
var modifiers: Array = []
var _cached_values: Dictionary = {}


func set_profile(new_profile: Resource) -> void:
	profile = new_profile
	recalculate()


func add_modifier(modifier: RefCounted) -> void:
	if modifier == null:
		return
	modifiers.append(modifier)
	modifier_added.emit(modifier.source_id, modifier.attribute_id)
	recalculate()


func remove_modifier(modifier: RefCounted) -> void:
	if modifier == null:
		return
	if not modifiers.has(modifier):
		return
	modifiers.erase(modifier)
	modifier_removed.emit(modifier.source_id, modifier.attribute_id)
	recalculate()


func remove_modifiers_by_source(source_id: StringName) -> void:
	var removed: Array = []
	for modifier in modifiers:
		if modifier != null and modifier.source_id == source_id:
			removed.append(modifier)
	for modifier in removed:
		modifiers.erase(modifier)
		modifier_removed.emit(modifier.source_id, modifier.attribute_id)
	if not removed.is_empty():
		recalculate()


func clear_modifiers() -> void:
	if modifiers.is_empty():
		return
	for modifier in modifiers:
		if modifier != null:
			modifier_removed.emit(modifier.source_id, modifier.attribute_id)
	modifiers.clear()
	recalculate()


func get_value(attribute_id: StringName) -> float:
	if _cached_values.is_empty():
		recalculate()
	return float(_cached_values.get(attribute_id, _get_base_value(attribute_id)))


func get_string_value(attribute_id: StringName, fallback_value: StringName = &"") -> StringName:
	if profile == null:
		return fallback_value
	match attribute_id:
		&"respawn_hp_mode":
			return profile.respawn_hp_mode
		&"respawn_energy_mode":
			return profile.respawn_energy_mode
		_:
			return fallback_value


func recalculate() -> void:
	var attribute_ids: Array[StringName] = [
		&"max_hp",
		&"max_energy",
		&"starting_hp",
		&"starting_energy",
		&"respawn_hp_value",
		&"respawn_energy_value",
		&"attack_power",
		&"defense_ratio",
		&"poise",
		&"stun_resistance",
		&"knockback_resistance",
		&"move_speed_scale",
		&"dash_scale",
		&"air_control_scale",
	]
	var previous_values := _cached_values.duplicate()
	_cached_values.clear()
	for attribute_id in attribute_ids:
		var next_value := _calculate_attribute_value(attribute_id)
		_cached_values[attribute_id] = next_value
		var previous_value := float(previous_values.get(attribute_id, next_value))
		if not is_equal_approx(previous_value, next_value):
			attribute_changed.emit(attribute_id, previous_value, next_value)
	attributes_recalculated.emit()


func _calculate_attribute_value(attribute_id: StringName) -> float:
	var base_value := _get_base_value(attribute_id)
	var flat_add_sum := 0.0
	var percent_add_sum := 0.0
	var multiplier_product := 1.0
	var override_found := false
	var override_priority := -2147483648
	var override_value := base_value
	for modifier in modifiers:
		if modifier == null or modifier.attribute_id != attribute_id:
			continue
		match modifier.operation_type:
			OP_FLAT_ADD:
				flat_add_sum += modifier.value
			OP_PERCENT_ADD:
				percent_add_sum += modifier.value
			OP_MULTIPLIER:
				multiplier_product *= modifier.value
			OP_OVERRIDE:
				if not override_found or modifier.priority >= override_priority:
					override_found = true
					override_priority = modifier.priority
					override_value = modifier.value
	if override_found:
		return override_value
	return ((base_value + flat_add_sum) * (1.0 + percent_add_sum)) * multiplier_product


func _get_base_value(attribute_id: StringName) -> float:
	if profile == null:
		return 0.0
	match attribute_id:
		&"max_hp":
			return profile.max_hp
		&"max_energy":
			return profile.max_energy
		&"starting_hp":
			return profile.starting_hp
		&"starting_energy":
			return profile.starting_energy
		&"respawn_hp_value":
			return profile.respawn_hp_value
		&"respawn_energy_value":
			return profile.respawn_energy_value
		&"attack_power":
			return profile.attack_power
		&"defense_ratio":
			return profile.defense_ratio
		&"poise":
			return profile.poise
		&"stun_resistance":
			return profile.stun_resistance
		&"knockback_resistance":
			return profile.knockback_resistance
		&"move_speed_scale":
			return profile.move_speed_scale
		&"dash_scale":
			return profile.dash_scale
		&"air_control_scale":
			return profile.air_control_scale
		_:
			return 0.0
