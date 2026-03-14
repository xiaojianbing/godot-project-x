class_name PlayerController
extends Node


var input_buffer := PlayerInputBuffer.new()
var input_snapshot := PlayerInputSnapshot.new()
var locomotion_motor := LocomotionMotor.new()
var locomotion_state_machine := LocomotionStateMachine.new()
var ground_detector := GroundDetector.new()
var wall_detector := WallDetector.new()
var ledge_detector := LedgeDetector.new()


@onready var actor: PlayerTestActor = get_parent() as PlayerTestActor


func _ready() -> void:
	if actor == null:
		push_error("PlayerController must be a child of PlayerTestActor.")
		return
	actor.controller = self
	actor._ensure_input_actions()
	actor._ensure_profiles()
	actor._setup_character_foundation()
	locomotion_state_machine.setup()
	var debug_service := get_node_or_null("/root/DebugService")
	if debug_service != null:
		debug_service.log_info(&"player_controller", "PlayerController ready.")


func _physics_process(delta: float) -> void:
	if actor == null:
		return
	if actor.context == null or actor.context.motion_profile == null:
		return
	input_snapshot.update_from_input()
	input_buffer.update(delta)
	actor._handle_input_buffering()
	actor._update_runtime_timers(delta)
	actor._update_detection_rays()
	locomotion_state_machine.sync_from_actor(actor)
	locomotion_state_machine.update_physics(actor, delta)
	if not actor.should_skip_motion_commit():
		locomotion_motor.move(actor)
	locomotion_state_machine.sync_from_actor(actor)
	actor._update_runtime_signals()


func get_current_state_id() -> StringName:
	return locomotion_state_machine.get_current_state_id()


func get_input_snapshot() -> PlayerInputSnapshot:
	return input_snapshot
