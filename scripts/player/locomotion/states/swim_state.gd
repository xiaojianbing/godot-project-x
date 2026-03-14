class_name SwimState
extends StateNode


func physics_update(context: Variant, delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._apply_swim_movement(delta)
