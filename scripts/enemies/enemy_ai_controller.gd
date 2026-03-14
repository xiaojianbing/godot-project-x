class_name EnemyAiController
extends RefCounted


var aggro_range: float = 420.0
var melee_range: float = 72.0
var preferred_range: float = 180.0


func configure(owner_aggro_range: float, owner_melee_range: float, owner_preferred_range: float) -> void:
	aggro_range = owner_aggro_range
	melee_range = owner_melee_range
	preferred_range = owner_preferred_range


func evaluate(
	actor_position: Vector2,
	player: Node2D,
	current_velocity_x: float,
	motion_profile: CharacterMotionProfile,
	attack_cycle_remaining: float,
	projectile_cycle_remaining: float,
	delta: float
) -> Dictionary:
	if player == null:
		return {
			"velocity_x": move_toward(current_velocity_x, 0.0, motion_profile.ground_deceleration * delta),
			"action_tag": &"enemy_idle",
			"start_melee": false,
			"start_projectile": false,
		}
	var distance := actor_position.distance_to(player.global_position)
	if distance > aggro_range:
		return {
			"velocity_x": move_toward(current_velocity_x, 0.0, motion_profile.ground_deceleration * delta),
			"action_tag": &"enemy_idle",
			"start_melee": false,
			"start_projectile": false,
		}
	if attack_cycle_remaining <= 0.0 and distance <= melee_range:
		return {
			"velocity_x": 0.0,
			"action_tag": &"enemy_attack",
			"start_melee": true,
			"start_projectile": false,
		}
	if projectile_cycle_remaining <= 0.0 and distance > melee_range and distance <= aggro_range:
		return {
			"velocity_x": 0.0,
			"action_tag": &"enemy_projectile",
			"start_melee": false,
			"start_projectile": true,
		}
	var direction_x := signf(player.global_position.x - actor_position.x)
	if distance > preferred_range:
		return {
			"velocity_x": move_toward(current_velocity_x, direction_x * motion_profile.base_move_speed, motion_profile.ground_acceleration * delta),
			"action_tag": &"enemy_move",
			"start_melee": false,
			"start_projectile": false,
		}
	return {
		"velocity_x": move_toward(current_velocity_x, 0.0, motion_profile.ground_deceleration * delta),
		"action_tag": &"enemy_idle",
		"start_melee": false,
		"start_projectile": false,
	}
