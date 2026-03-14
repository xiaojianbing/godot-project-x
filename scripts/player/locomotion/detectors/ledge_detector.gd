class_name LedgeDetector
extends RefCounted


func update_rays(head_ray: RayCast2D, ledge_ray_forward: RayCast2D, ledge_ray_down: RayCast2D, facing: int) -> void:
	var facing_float := float(1 if facing >= 0 else -1)
	head_ray.target_position = Vector2(0.0, -8.0)
	ledge_ray_forward.position = Vector2(10.0 * facing_float, -8.0)
	ledge_ray_forward.target_position = Vector2(8.0 * facing_float, 0.0)
	ledge_ray_down.position = Vector2(18.0 * facing_float, -24.0)
	ledge_ray_down.target_position = Vector2(0.0, 24.0)
	head_ray.force_raycast_update()
	ledge_ray_forward.force_raycast_update()
	ledge_ray_down.force_raycast_update()


func can_ledge_climb(actor: CharacterBody2D, head_ray: RayCast2D, ledge_ray_forward: RayCast2D, ledge_ray_down: RayCast2D, dash_time_remaining: float) -> bool:
	if actor == null:
		return false
	if actor.is_on_floor() or dash_time_remaining > 0.0:
		return false
	if not actor.is_on_wall_only():
		return false
	if actor.velocity.y < 0.0:
		return false
	if head_ray.is_colliding():
		return false
	if ledge_ray_forward.is_colliding():
		return false
	return ledge_ray_down.is_colliding()


func get_snap_position(ledge_ray_down: RayCast2D, facing: int) -> Vector2:
	var collision_point := ledge_ray_down.get_collision_point()
	var facing_float := float(1 if facing >= 0 else -1)
	return Vector2(collision_point.x - 10.0 * facing_float, collision_point.y - 16.0)


func get_ledge_point(ledge_ray_down: RayCast2D) -> Vector2:
	return ledge_ray_down.get_collision_point()
