class_name CombatChasePoint
extends GrapplePoint


var follow_target: Node2D = null
var follow_offset: Vector2 = Vector2.ZERO
var lifetime_remaining: float = 0.0


func setup(target: Node2D, offset: Vector2, lifetime: float) -> void:
	follow_target = target
	follow_offset = offset
	lifetime_remaining = maxf(lifetime, 0.0)
	if follow_target != null:
		global_position = follow_target.global_position + follow_offset


func _physics_process(delta: float) -> void:
	lifetime_remaining = maxf(0.0, lifetime_remaining - delta)
	if not can_grapple():
		queue_free()
		return
	global_position = follow_target.global_position + follow_offset


func can_grapple() -> bool:
	return enabled and lifetime_remaining > 0.0 and is_instance_valid(follow_target)


func get_grapple_priority_bonus() -> float:
	return 240.0


func is_combat_chase_point() -> bool:
	return true
