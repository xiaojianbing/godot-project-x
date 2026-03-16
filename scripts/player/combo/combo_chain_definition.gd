class_name ComboChainDefinition
extends Resource


const COMBO_STEP_DEFINITION_SCRIPT := preload("res://scripts/player/combo/combo_step_definition.gd")


@export var chain_id: StringName = &""
@export var entry_conditions: Array[StringName] = []
@export var step_sequence: Array[Resource] = []
@export var finisher_tags: Array[StringName] = []
@export var resource_hooks: Array[StringName] = []
@export var target_reaction_profile: StringName = &""


func find_step(step_id: StringName) -> Resource:
	for step in step_sequence:
		if step != null and step.step_id == step_id:
			return step
	return null
