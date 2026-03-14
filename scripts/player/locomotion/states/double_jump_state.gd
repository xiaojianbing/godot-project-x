class_name DoubleJumpState
extends StateNode


func physics_update(context: Variant, delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._try_start_ledge_climb()
		actor._try_consume_grapple()
		actor._try_consume_dash()
		actor._apply_horizontal_movement(delta)
		actor._apply_vertical_movement(delta)
		actor._apply_corner_correction()
