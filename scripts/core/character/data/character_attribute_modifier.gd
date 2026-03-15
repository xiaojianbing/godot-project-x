class_name CharacterAttributeModifier
extends RefCounted


const OP_FLAT_ADD := &"flat_add"
const OP_PERCENT_ADD := &"percent_add"
const OP_MULTIPLIER := &"multiplier"
const OP_OVERRIDE := &"override"


var attribute_id: StringName = &""
var operation_type: StringName = OP_FLAT_ADD
var value: float = 0.0
var source_id: StringName = &""
var stack_group: StringName = &""
var priority: int = 0
var duration: float = -1.0
var tags: Array[StringName] = []


static func create(
	new_attribute_id: StringName,
	new_operation_type: StringName,
	new_value: float,
	new_source_id: StringName = &"",
	new_priority: int = 0

) -> CharacterAttributeModifier:
	var modifier := CharacterAttributeModifier.new()
	modifier.attribute_id = new_attribute_id
	modifier.operation_type = new_operation_type
	modifier.value = new_value
	modifier.source_id = new_source_id
	modifier.priority = new_priority
	return modifier
