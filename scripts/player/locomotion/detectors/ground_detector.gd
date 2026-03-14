class_name GroundDetector
extends RefCounted


func is_grounded(actor: CharacterBody2D) -> bool:
	return actor != null and actor.is_on_floor()


func update_coyote_time(actor: CharacterBody2D, remaining: float, coyote_time: float, delta: float) -> float:
	if is_grounded(actor):
		return coyote_time
	return maxf(0.0, remaining - delta)
