class_name LocomotionMotor
extends RefCounted


func get_target_speed(move_axis: float, move_speed: float, speed_scale: float) -> float:
	return move_axis * move_speed * speed_scale


func get_horizontal_acceleration(is_grounded: bool, move_axis: float, ground_acceleration: float, ground_deceleration: float, air_control_multiplier: float) -> float:
	if is_zero_approx(move_axis):
		return ground_deceleration
	if is_grounded:
		return ground_acceleration
	return ground_acceleration * air_control_multiplier


func apply_horizontal_velocity(body: CharacterBody2D, target_speed: float, acceleration: float, delta: float) -> void:
	body.velocity.x = move_toward(body.velocity.x, target_speed, acceleration * delta)


func get_gravity(is_jump_held: bool, vertical_velocity: float, gravity_up: float, gravity_down: float) -> float:
	if vertical_velocity < 0.0 and is_jump_held:
		return gravity_up
	return gravity_down


func apply_gravity(body: CharacterBody2D, gravity: float, delta: float) -> void:
	body.velocity.y += gravity * delta


func apply_jump_velocity(body: CharacterBody2D, jump_velocity: float) -> void:
	body.velocity.y = jump_velocity


func apply_wall_jump_velocity(body: CharacterBody2D, horizontal_speed: float, vertical_speed: float) -> void:
	body.velocity.x = horizontal_speed
	body.velocity.y = vertical_speed


func apply_dash_velocity(body: CharacterBody2D, direction: Vector2, dash_speed: float) -> void:
	body.velocity = direction.normalized() * dash_speed


func apply_swim_velocity(body: CharacterBody2D, target_velocity: Vector2, acceleration: float, deceleration: float, delta: float) -> void:
	var horizontal_rate := acceleration if not is_zero_approx(target_velocity.x) else deceleration
	var vertical_rate := acceleration if not is_zero_approx(target_velocity.y) else deceleration
	body.velocity.x = move_toward(body.velocity.x, target_velocity.x, horizontal_rate * delta)
	body.velocity.y = move_toward(body.velocity.y, target_velocity.y, vertical_rate * delta)


func apply_grapple_velocity(body: CharacterBody2D, target_point: Vector2, target_speed: float, acceleration: float, delta: float) -> void:
	var direction := (target_point - body.global_position).normalized()
	var target_velocity := direction * target_speed
	body.velocity = body.velocity.move_toward(target_velocity, acceleration * delta)


func apply_grapple_release_decay(body: CharacterBody2D, deceleration: float, delta: float) -> void:
	body.velocity = body.velocity.move_toward(Vector2.ZERO, deceleration * delta)


func get_wall_slide_speed(free_fall_reference_speed: float, wall_slide_speed_ratio: float) -> float:
	return free_fall_reference_speed * wall_slide_speed_ratio


func get_dash_direction(move_axis: float, facing_direction: int) -> Vector2:
	if not is_zero_approx(move_axis):
		return Vector2(sign(move_axis), 0.0)
	return Vector2(float(1 if facing_direction >= 0 else -1), 0.0)


func move(body: CharacterBody2D) -> void:
	body.move_and_slide()
