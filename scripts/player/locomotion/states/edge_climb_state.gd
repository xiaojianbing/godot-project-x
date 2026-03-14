class_name EdgeClimbState
extends StateNode


func physics_update(context: Variant, delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._try_start_ledge_climb()
		actor._update_ledge_climb_motion()
		actor._apply_horizontal_movement(delta)
		actor._apply_vertical_movement(delta)
