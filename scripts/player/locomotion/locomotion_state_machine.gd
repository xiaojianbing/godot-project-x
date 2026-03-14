class_name LocomotionStateMachine
extends RefCounted


var _driver := StateMachineDriver.new()


func setup() -> void:
	_driver.register_state(&"idle", IdleState.new())
	_driver.register_state(&"run", RunState.new())
	_driver.register_state(&"crouch", CrouchState.new())
	_driver.register_state(&"crouch_move", CrouchMoveState.new())
	_driver.register_state(&"jump", JumpState.new())
	_driver.register_state(&"fall", FallState.new())
	_driver.register_state(&"double_jump", DoubleJumpState.new())
	_driver.register_state(&"dash", DashState.new())
	_driver.register_state(&"crouch_dash", CrouchDashState.new())
	_driver.register_state(&"grapple", GrappleState.new())
	_driver.register_state(&"swim", SwimState.new())
	_driver.register_state(&"wall_slide", WallSlideState.new())
	_driver.register_state(&"wall_jump", WallJumpState.new())
	_driver.register_state(&"edge_idle", EdgeIdleState.new())
	_driver.register_state(&"edge_climb", EdgeClimbState.new())


func sync_from_actor(actor: PlayerTestActor) -> void:
	if actor == null:
		return
	var next_state := _resolve_state(actor)
	if _driver.current_state_id != next_state:
		_driver.request_transition(next_state, actor)


func update_physics(actor: PlayerTestActor, delta: float) -> void:
	_driver.update_physics(actor, delta)


func get_current_state_id() -> StringName:
	return _driver.current_state_id


func _resolve_state(actor: PlayerTestActor) -> StringName:
	if actor.is_edge_climbing():
		return &"edge_climb"
	if actor.is_grappling():
		return &"grapple"
	if actor.is_swimming():
		return &"swim"
	if actor.is_edge_hanging():
		return &"edge_idle"
	if actor.is_crouch_dashing():
		return &"crouch_dash"
	if actor.is_dashing():
		return &"dash"
	if actor.is_wall_sliding():
		return &"wall_slide"
	if actor.is_wall_jumping():
		return &"wall_jump"
	if actor.is_double_jumping():
		return &"double_jump"
	if actor.is_crouching() and actor.is_on_floor():
		return &"crouch_move" if actor.has_crouch_move_input() else &"crouch"
	if not actor.is_on_floor():
		return &"jump" if actor.velocity.y < 0.0 else &"fall"
	return &"run" if absf(actor.velocity.x) > 1.0 else &"idle"
