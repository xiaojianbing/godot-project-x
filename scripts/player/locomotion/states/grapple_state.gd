class_name GrappleState
extends StateNode


func physics_update(context: Variant, _delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._apply_grapple_motion()
