class_name EdgeIdleState
extends StateNode


func enter(context: Variant) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._enter_edge_idle()


func physics_update(context: Variant, _delta: float) -> void:
	if context is PlayerTestActor:
		var actor := context as PlayerTestActor
		actor._update_edge_idle()
