class_name CrouchState
extends StateNode


func physics_update(context: Variant, delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._try_consume_dash()
		actor._apply_horizontal_movement(delta)
		actor._apply_vertical_movement(delta)
		actor._try_consume_jump()
