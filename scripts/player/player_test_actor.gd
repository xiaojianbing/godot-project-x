class_name PlayerTestActor
extends CharacterBody2D


const PLAYER_PROJECTILE_SCENE := preload("res://scenes/common/parry_projectile.tscn")
const DASH_AFTERIMAGE_SCRIPT := preload("res://scripts/common/dash_afterimage.gd")
const WORLD_COLLISION_MASK := 1
const ENEMY_BODY_COLLISION_MASK := 4
const PLAYER_DEFAULT_COLLISION_MASK := WORLD_COLLISION_MASK | ENEMY_BODY_COLLISION_MASK
const LIGHT_ATTACK_OUTLINE_COLOR := Color(0.36, 0.94, 0.48, 0.95)
const HEAVY_ATTACK_OUTLINE_COLOR := Color(0.14, 0.96, 0.76, 0.98)


@export var combat_profile: CharacterCombatProfile
@export var motion_profile: CharacterMotionProfile
@export var attributes_profile: Resource
@export var double_jump_unlocked: bool = true
@export var swim_unlocked: bool = true
@export var grapple_unlocked: bool = true


var stats: CharacterStats
var signals: CharacterSignals
var context: CharacterContext
var damage_receiver: DamageReceiver
var controller: PlayerController

var _coyote_time_remaining: float = 0.0
var _dash_time_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0
var _wall_jump_input_lock_remaining: float = 0.0
var _ledge_climb_remaining: float = 0.0
var _ledge_regrab_lock_remaining: float = 0.0
var _ledge_climb_total_duration: float = 0.0
var _edge_idle_input_guard_remaining: float = 0.0
var _grapple_min_remaining: float = 0.0
var _grapple_release_remaining: float = 0.0
var _parry_window_remaining: float = 0.0
var _combat_invincible_remaining: float = 0.0
var _attack_active_remaining: float = 0.0
var _attack_recovery_remaining: float = 0.0
var _hurt_lock_remaining: float = 0.0
var _hurt_flash_remaining: float = 0.0
var _hurt_knockback_velocity: Vector2 = Vector2.ZERO
var _dash_afterimage_remaining: float = 0.0
var _parry_flash_remaining: float = 0.0
var _is_shoot_aiming: bool = false
var _shoot_aim_direction: Vector2 = Vector2.RIGHT
var _double_jump_state_remaining: float = 0.0
var _attack_damage_scale: float = 1.0
var _dash_direction := Vector2.RIGHT
var _ledge_top_point := Vector2.ZERO
var _ledge_climb_start_position := Vector2.ZERO
var _ledge_climb_target_position := Vector2.ZERO
var _current_grapple_point: GrapplePoint = null
var _grapple_initial_distance: float = 0.0
var _air_jumps_remaining: int = 0
var _is_in_shallow_water: bool = false
var _is_in_deep_water: bool = false
var _is_swimming: bool = false
var _is_crouching: bool = false
var _is_crouch_dashing: bool = false
var _is_edge_hanging: bool = false
var _was_wall_sliding_last_frame: bool = false
var _attack_hit_ids: Dictionary = {}
var _last_jump_failure_reason: String = "ready"
var _last_dash_failure_reason: String = "ready"
var _last_swim_failure_reason: String = "ready"
var _last_grapple_failure_reason: String = "ready"
var _last_combat_result: String = "ready"
var _last_attack_action: String = "none"
var _active_attack_action: StringName = &"attack_light"

@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _sprite_root: Node2D = $SpriteRoot
@onready var _body_outline: StateOutline2D = $BodyOutline
@onready var _guard_outline: StateOutline2D = $GuardOutline
@onready var _aim_guide: AimGuide2D = $AimGuide
@onready var _attack_hitbox: Area2D = $HitboxAnchor/AttackHitbox
@onready var _attack_hitbox_shape: CollisionShape2D = $HitboxAnchor/AttackHitbox/CollisionShape2D
@onready var _head_ray: RayCast2D = $HeadRay
@onready var _ledge_ray_forward: RayCast2D = $LedgeRayForward
@onready var _ledge_ray_down: RayCast2D = $LedgeRayDown


func _log_edge(message: String) -> void:
	var debug_service := get_node_or_null("/root/DebugService")
	if debug_service != null:
		debug_service.log_info(&"edge", message)


func _log_wall(message: String) -> void:
	var debug_service := get_node_or_null("/root/DebugService")
	if debug_service != null:
		debug_service.log_info(&"wall", message)


func _ensure_runtime_nodes() -> void:
	if _body_shape == null:
		_body_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _hurtbox == null:
		_hurtbox = get_node_or_null("Hurtbox") as Area2D
	if _hurtbox_shape == null:
		_hurtbox_shape = get_node_or_null("Hurtbox/CollisionShape2D") as CollisionShape2D
	if _sprite_root == null:
		_sprite_root = get_node_or_null("SpriteRoot") as Node2D
	if _head_ray == null:
		_head_ray = get_node_or_null("HeadRay") as RayCast2D
	if _attack_hitbox == null:
		_attack_hitbox = get_node_or_null("HitboxAnchor/AttackHitbox") as Area2D
	if _attack_hitbox_shape == null:
		_attack_hitbox_shape = get_node_or_null("HitboxAnchor/AttackHitbox/CollisionShape2D") as CollisionShape2D
	if _ledge_ray_forward == null:
		_ledge_ray_forward = get_node_or_null("LedgeRayForward") as RayCast2D
	if _ledge_ray_down == null:
		_ledge_ray_down = get_node_or_null("LedgeRayDown") as RayCast2D


func apply_debug_damage(amount: float) -> DamageResult:
	if damage_receiver == null:
		return DamageResult.new()
	return damage_receiver.receive_hit({"damage": amount})


func apply_debug_heal(amount: float) -> HealResult:
	if stats == null:
		return HealResult.new()
	return stats.heal(amount)


func get_character_context() -> CharacterContext:
	return context


func get_input_buffer() -> PlayerInputBuffer:
	return controller.input_buffer if controller != null else null


func get_locomotion_motor() -> LocomotionMotor:
	return controller.locomotion_motor if controller != null else null


func get_locomotion_state_machine() -> LocomotionStateMachine:
	return controller.locomotion_state_machine if controller != null else null


func get_input_snapshot() -> PlayerInputSnapshot:
	return controller.get_input_snapshot() if controller != null else null


func _ensure_profiles() -> void:
	if combat_profile == null:
		combat_profile = CharacterCombatProfile.new()
	if motion_profile == null:
		motion_profile = CharacterMotionProfile.new()


func _ensure_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_ensure_key_action("dash", [KEY_SHIFT, KEY_J])
	_ensure_key_action("guard", [KEY_L, KEY_SEMICOLON])
	_ensure_key_action("attack_light", [KEY_F, KEY_H])
	_ensure_key_action("attack_heavy", [KEY_G, KEY_Y])
	_ensure_key_action("shoot", [KEY_R, KEY_U])
	_ensure_key_action("aim_left", [KEY_LEFT])
	_ensure_key_action("aim_right", [KEY_RIGHT])
	_ensure_key_action("aim_up", [KEY_UP])
	_ensure_key_action("aim_down", [KEY_DOWN])
	_ensure_key_action("grapple", [KEY_E, KEY_K])
	_ensure_joy_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_joy_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_joy_axis_action("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_joy_axis_action("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_ensure_joy_axis_action("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_ensure_joy_axis_action("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_ensure_joy_axis_action("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_ensure_joy_axis_action("aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	_ensure_joy_axis_action("dash", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_ensure_joy_axis_action("grapple", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_ensure_joy_button_action("guard", JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_joy_button_action("jump", JOY_BUTTON_A)
	_ensure_joy_button_action("attack_light", JOY_BUTTON_X)
	_ensure_joy_button_action("attack_heavy", JOY_BUTTON_Y)
	_ensure_joy_button_action("shoot", JOY_BUTTON_B)


func _ensure_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		if _action_has_key(action_name, keycode):
			continue
		var event := InputEventKey.new()
		event.physical_keycode = keycode as Key
		InputMap.action_add_event(action_name, event)


func _ensure_joy_axis_action(action_name: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if _action_has_joy_axis(action_name, axis, axis_value):
		return
	var event := InputEventJoypadMotion.new()
	event.axis = axis as JoyAxis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)


func _ensure_joy_button_action(action_name: StringName, button_index: JoyButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if _action_has_joy_button(action_name, button_index):
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button_index as JoyButton
	InputMap.action_add_event(action_name, event)


func _action_has_key(action_name: StringName, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _action_has_joy_axis(action_name: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _action_has_joy_button(action_name: StringName, button_index: JoyButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false


func _setup_character_foundation() -> void:
	_ensure_runtime_nodes()
	stats = CharacterStats.new()
	if attributes_profile != null:
		stats.configure_from_attributes_profile(attributes_profile)
	else:
		stats.configure_from_profile(combat_profile)
	signals = CharacterSignals.new()
	context = CharacterContext.new()
	context.setup(self, stats, signals, combat_profile, motion_profile, null, attributes_profile, stats.attribute_set)
	collision_mask = PLAYER_DEFAULT_COLLISION_MASK
	damage_receiver = DamageReceiver.new()
	damage_receiver.setup(context)
	damage_receiver.hurt_requested.connect(_on_hurt_requested)
	damage_receiver.death_requested.connect(_on_death_requested)
	_reset_air_jump_charges()
	_update_crouch_collision(false)
	if _attack_hitbox != null:
		_attack_hitbox.monitoring = false


func _handle_input_buffering() -> void:
	var input_snapshot := get_input_snapshot()
	var input_buffer := get_input_buffer()
	if input_buffer == null or input_snapshot == null:
		return
	if input_snapshot.jump_just_pressed:
		input_buffer.buffer_jump(motion_profile.jump_buffer_time)
	if input_snapshot.dash_just_pressed:
		input_buffer.buffer_dash(0.12)
	if input_snapshot.grapple_just_pressed:
		input_buffer.buffer_grapple(0.16)


func _update_runtime_timers(delta: float) -> void:
	_dash_cooldown_remaining = maxf(0.0, _dash_cooldown_remaining - delta)
	_wall_jump_input_lock_remaining = maxf(0.0, _wall_jump_input_lock_remaining - delta)
	_ledge_climb_remaining = maxf(0.0, _ledge_climb_remaining - delta)
	_ledge_regrab_lock_remaining = maxf(0.0, _ledge_regrab_lock_remaining - delta)
	_edge_idle_input_guard_remaining = maxf(0.0, _edge_idle_input_guard_remaining - delta)
	_grapple_min_remaining = maxf(0.0, _grapple_min_remaining - delta)
	_grapple_release_remaining = maxf(0.0, _grapple_release_remaining - delta)
	_parry_window_remaining = maxf(0.0, _parry_window_remaining - delta)
	_combat_invincible_remaining = maxf(0.0, _combat_invincible_remaining - delta)
	_attack_active_remaining = maxf(0.0, _attack_active_remaining - delta)
	_attack_recovery_remaining = maxf(0.0, _attack_recovery_remaining - delta)
	_hurt_lock_remaining = maxf(0.0, _hurt_lock_remaining - delta)
	_hurt_flash_remaining = maxf(0.0, _hurt_flash_remaining - delta)
	_hurt_knockback_velocity = _hurt_knockback_velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
	_dash_afterimage_remaining = maxf(0.0, _dash_afterimage_remaining - delta)
	_parry_flash_remaining = maxf(0.0, _parry_flash_remaining - delta)
	_double_jump_state_remaining = maxf(0.0, _double_jump_state_remaining - delta)
	if controller != null:
		_coyote_time_remaining = controller.ground_detector.update_coyote_time(self, _coyote_time_remaining, motion_profile.coyote_time, delta)


func _update_detection_rays() -> void:
	_ensure_runtime_nodes()
	if controller == null:
		return
	var facing := signs_to_int(signals.facing_direction if signals != null else 1)
	controller.ledge_detector.update_rays(_head_ray, _ledge_ray_forward, _ledge_ray_down, facing)


func _apply_horizontal_movement(delta: float) -> void:
	var locomotion_motor := get_locomotion_motor()
	if locomotion_motor == null:
		return
	if _dash_time_remaining > 0.0:
		var dash_speed := motion_profile.crouch_dash_speed if _is_crouch_dashing else motion_profile.dash_speed
		velocity.x = _dash_direction.x * dash_speed * stats.dash_scale
		return
	if _hurt_lock_remaining > 0.0:
		velocity.x = _hurt_knockback_velocity.x
		return
	if is_grappling():
		return
	if _is_swimming:
		return
	if _is_edge_hanging:
		velocity.x = 0.0
		return
	if _ledge_climb_remaining > 0.0:
		velocity.x = 0.0
		return
	if _is_shoot_aiming:
		velocity.x = move_toward(velocity.x, 0.0, motion_profile.ground_deceleration * delta)
		return
	var input_snapshot := get_input_snapshot()
	var input_axis := input_snapshot.move_axis if input_snapshot != null else 0.0
	if _wall_jump_input_lock_remaining > 0.0:
		input_axis = 0.0
	var move_speed := motion_profile.crouch_move_speed if _is_crouching and is_on_floor() else motion_profile.base_move_speed
	if _is_in_shallow_water:
		move_speed *= motion_profile.special_terrain_speed_multiplier
	var target_speed := locomotion_motor.get_target_speed(input_axis, move_speed, stats.move_speed_scale)
	var acceleration := locomotion_motor.get_horizontal_acceleration(is_on_floor(), input_axis, motion_profile.ground_acceleration, motion_profile.ground_deceleration, motion_profile.air_control_multiplier)
	locomotion_motor.apply_horizontal_velocity(self, target_speed, acceleration, delta)
	if not is_zero_approx(input_axis):
		context.set_facing_direction(sign(input_axis))


func _apply_vertical_movement(delta: float) -> void:
	var locomotion_motor := get_locomotion_motor()
	if locomotion_motor == null:
		return
	if _dash_time_remaining > 0.0:
		_dash_time_remaining = maxf(0.0, _dash_time_remaining - delta)
		velocity.y = 0.0
		return
	if _hurt_lock_remaining > 0.0:
		var hurt_gravity := locomotion_motor.get_gravity(false, velocity.y, motion_profile.gravity_up, motion_profile.gravity_down)
		if _hurt_knockback_velocity.y < velocity.y:
			velocity.y = _hurt_knockback_velocity.y
		locomotion_motor.apply_gravity(self, hurt_gravity, delta)
		return
	if is_grappling():
		return
	if _is_swimming:
		return
	if _is_edge_hanging:
		velocity.y = 0.0
		return
	if _ledge_climb_remaining > 0.0:
		velocity.y = 0.0
		return
	var input_snapshot := get_input_snapshot()
	var gravity := locomotion_motor.get_gravity(input_snapshot.jump_pressed if input_snapshot != null else false, velocity.y, motion_profile.gravity_up, motion_profile.gravity_down)
	if _is_wall_sliding():
		var wall_slide_speed := locomotion_motor.get_wall_slide_speed(motion_profile.free_fall_reference_speed, motion_profile.wall_slide_speed_ratio)
		if not _was_wall_sliding_last_frame:
			_log_wall("enter_slide vel_y=%.2f target=%.2f floor=%s wall=%s" % [velocity.y, wall_slide_speed, str(is_on_floor()), str(is_on_wall_only())])
		# 之前这里只做了上限裁剪：低速进入墙滑时会把很小的下落速度原样保留，导致墙滑偶发地非常慢。
		velocity.y = move_toward(velocity.y, wall_slide_speed, motion_profile.gravity_down * delta)
		gravity = 0.0
		if velocity.y < wall_slide_speed * 0.8:
			_log_wall("slow_slide vel_y=%.2f target=%.2f" % [velocity.y, wall_slide_speed])
	locomotion_motor.apply_gravity(self, gravity, delta)


func _try_consume_jump() -> void:
	var input_buffer := get_input_buffer()
	var locomotion_motor := get_locomotion_motor()
	if input_buffer == null or locomotion_motor == null:
		return
	if not input_buffer.has_buffered_jump():
		_last_jump_failure_reason = "no_buffer"
		return
	if _can_wall_jump():
		# 墙跳需要明确反推和短暂输入锁，避免角色立刻贴回原墙，保持结果稳定可读。
		input_buffer.consume_jump()
		_wall_jump_input_lock_remaining = motion_profile.wall_jump_input_lock_time
		var wall_normal := controller.wall_detector.get_wall_normal(self) if controller != null else get_wall_normal()
		var horizontal_speed := wall_normal.x * motion_profile.wall_jump_horizontal_speed
		locomotion_motor.apply_wall_jump_velocity(self, horizontal_speed, motion_profile.wall_jump_vertical_speed)
		context.set_facing_direction(sign(horizontal_speed))
		if signals != null:
			signals.is_grounded = false
			signals.current_action_tag = &"wall_jump"
		_last_jump_failure_reason = "wall_jump"
		return
	if _can_ground_jump():
		# 这里把土狼时间和跳跃缓冲统一收口，避免玩家明明按对了却因为边缘帧误差跳不出来。
		input_buffer.consume_jump()
		_coyote_time_remaining = 0.0
		_exit_crouch_if_possible(true)
		locomotion_motor.apply_jump_velocity(self, motion_profile.jump_velocity)
		if signals != null:
			signals.is_grounded = false
			signals.current_action_tag = &"jump"
		_last_jump_failure_reason = "jumped"
		return
	if _can_double_jump():
		input_buffer.consume_jump()
		_air_jumps_remaining = max(0, _air_jumps_remaining - 1)
		_double_jump_state_remaining = 0.12
		_exit_crouch_if_possible(true)
		locomotion_motor.apply_jump_velocity(self, motion_profile.double_jump_velocity)
		if signals != null:
			signals.is_grounded = false
			signals.current_action_tag = &"double_jump"
		_last_jump_failure_reason = "double_jump"
		return
	if not _can_jump():
		_last_jump_failure_reason = _get_jump_failure_reason()
		return


func _try_consume_grapple() -> void:
	var input_buffer := get_input_buffer()
	if input_buffer == null:
		return
	if not input_buffer.has_buffered_grapple():
		_last_grapple_failure_reason = "no_buffer"
		return
	if not _can_grapple():
		_last_grapple_failure_reason = _get_grapple_failure_reason()
		return
	var grapple_point := _find_best_grapple_point()
	if grapple_point == null:
		_last_grapple_failure_reason = "no_point"
		return
	input_buffer.consume_grapple()
	_exit_edge_idle(false)
	_current_grapple_point = grapple_point
	_grapple_min_remaining = motion_profile.grapple_min_pull_duration
	_grapple_release_remaining = 0.0
	_grapple_initial_distance = global_position.distance_to(grapple_point.global_position)
	var initial_speed := motion_profile.grapple_pull_speed * motion_profile.grapple_initial_speed_ratio
	velocity = (grapple_point.global_position - global_position).normalized() * initial_speed
	if signals != null:
		signals.current_action_tag = &"grapple"
	_last_grapple_failure_reason = "grappled"


func _apply_grapple_motion() -> void:
	var locomotion_motor := get_locomotion_motor()
	if locomotion_motor == null:
		return
	if _current_grapple_point == null:
		if _grapple_release_remaining > 0.0:
			locomotion_motor.apply_grapple_release_decay(self, motion_profile.grapple_release_deceleration, get_physics_process_delta_time())
			if signals != null:
				signals.current_action_tag = &"grapple"
		return
	if not is_instance_valid(_current_grapple_point) or not _current_grapple_point.can_grapple():
		_release_grapple("point_invalid")
		return
	var target_point := _current_grapple_point.global_position
	var distance := global_position.distance_to(target_point)
	if distance <= motion_profile.grapple_arrive_threshold and _grapple_min_remaining <= 0.0:
		_release_grapple("arrived")
		return
	var start_distance := maxf(_grapple_initial_distance, motion_profile.grapple_arrive_threshold + 1.0)
	var progress := clampf(1.0 - distance / start_distance, 0.0, 1.0)
	var speed_ratio := motion_profile.grapple_initial_speed_ratio + (1.0 - motion_profile.grapple_initial_speed_ratio) * pow(progress, 0.55)
	var target_speed := motion_profile.grapple_pull_speed * speed_ratio
	# 这里让钩索拉拽表现为“先被带动、后猛烈加速”，越接近钩点越快，避免整段速度完全恒定。
	locomotion_motor.apply_grapple_velocity(self, target_point, target_speed, motion_profile.grapple_release_deceleration, get_physics_process_delta_time())
	if signals != null:
		signals.current_action_tag = &"grapple"


func _apply_swim_movement(delta: float) -> void:
	var locomotion_motor := get_locomotion_motor()
	var input_snapshot := get_input_snapshot()
	if locomotion_motor == null or input_snapshot == null:
		return
	var vertical_input := 0.0
	if input_snapshot.move_up_pressed:
		vertical_input -= 1.0
	if input_snapshot.move_down_pressed:
		vertical_input += 1.0
	var target_velocity := Vector2(
		input_snapshot.move_axis * motion_profile.swim_horizontal_speed * stats.move_speed_scale,
		vertical_input * motion_profile.swim_vertical_speed - motion_profile.swim_buoyancy
	)
	locomotion_motor.apply_swim_velocity(self, target_velocity, motion_profile.swim_acceleration, motion_profile.swim_deceleration, delta)


func _try_consume_dash() -> void:
	var input_buffer := get_input_buffer()
	var locomotion_motor := get_locomotion_motor()
	var input_snapshot := get_input_snapshot()
	if input_buffer == null or locomotion_motor == null:
		return
	if not input_buffer.has_buffered_dash():
		_last_dash_failure_reason = "no_buffer"
		return
	if not _can_dash():
		_last_dash_failure_reason = _get_dash_failure_reason()
		return
	input_buffer.consume_dash()
	_is_crouch_dashing = _should_crouch_dash()
	_dash_time_remaining = motion_profile.crouch_dash_duration if _is_crouch_dashing else motion_profile.dash_duration
	_dash_cooldown_remaining = motion_profile.dash_cooldown
	if _is_crouch_dashing:
		_enter_crouch()
	# 这里优先取当前输入方向，没有输入时回退到朝向，让冲刺稳定且符合直觉。
	_dash_direction = locomotion_motor.get_dash_direction(input_snapshot.move_axis if input_snapshot != null else 0.0, signals.facing_direction if signals != null else 1)
	var dash_speed := motion_profile.crouch_dash_speed if _is_crouch_dashing else motion_profile.dash_speed
	locomotion_motor.apply_dash_velocity(self, _dash_direction, dash_speed * stats.dash_scale)
	if signals != null:
		signals.is_invincible = true
		signals.current_action_tag = &"crouch_dash" if _is_crouch_dashing else &"dash"
	_last_dash_failure_reason = "crouch_dashed" if _is_crouch_dashing else "dashed"


func _try_start_ledge_climb() -> void:
	if _ledge_climb_remaining > 0.0:
		return
	if not _is_edge_hanging:
		return
	_log_edge("start_climb pos=%s ledge_top=%s input_up=%s" % [str(global_position), str(_ledge_top_point), str(get_input_snapshot().move_up_pressed if get_input_snapshot() != null else false)])
	_exit_edge_idle(false)
	_ledge_climb_total_duration = motion_profile.ledge_climb_duration
	_ledge_climb_remaining = _ledge_climb_total_duration
	_ledge_climb_start_position = global_position
	_ledge_climb_target_position = _get_ledge_climb_position()
	_log_edge("climb_path start=%s target=%s duration=%.2f" % [str(_ledge_climb_start_position), str(_ledge_climb_target_position), _ledge_climb_total_duration])
	velocity = Vector2.ZERO
	if signals != null:
		signals.current_action_tag = &"edge_climb"


func _update_ledge_climb_motion() -> void:
	if _ledge_climb_remaining <= 0.0 or _ledge_climb_total_duration <= 0.0:
		return
	var elapsed := _ledge_climb_total_duration - _ledge_climb_remaining
	var t := clampf(elapsed / _ledge_climb_total_duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	# 这里把翻越拆成“先上提、再前送”的两段轨迹，让挂边上台更像吃力攀爬，而不是瞬移到平台上。
	var up_phase := minf(eased / 0.72, 1.0)
	var forward_phase := 0.0
	if eased > 0.58:
		forward_phase = clampf((eased - 0.58) / 0.42, 0.0, 1.0)
	var current_x := lerpf(_ledge_climb_start_position.x, _ledge_climb_target_position.x, forward_phase)
	var current_y := lerpf(_ledge_climb_start_position.y, _ledge_climb_target_position.y, up_phase)
	global_position = Vector2(current_x, current_y)


func _try_enter_edge_idle() -> void:
	if _is_edge_hanging or _ledge_climb_remaining > 0.0:
		return
	if not _can_enter_edge_idle():
		return
	_log_edge("enter_edge_idle_requested pos=%s vel=%s facing=%s" % [str(global_position), str(velocity), str(signals.facing_direction if signals != null else 1)])
	_enter_edge_idle()


func _enter_edge_idle() -> void:
	if _is_edge_hanging:
		return
	_ledge_top_point = _get_ledge_point()
	if _ledge_top_point == Vector2.ZERO:
		return
		
	# 这里在进入挂边时立刻做一次 snap，对齐挂点并冻结速度，避免在边缘附近来回抖动。
	_is_edge_hanging = true
	_edge_idle_input_guard_remaining = 0.1
	velocity = Vector2.ZERO
	global_position = _get_ledge_hang_position()
	_log_edge("entered_edge_idle ledge_top=%s hang_pos=%s head_y=%.1f platform_y=%.1f" % [str(_ledge_top_point), str(global_position), global_position.y - motion_profile.standing_collision_height * 0.5, _ledge_top_point.y])
	if signals != null:
		signals.current_action_tag = &"edge_idle"


func _update_edge_idle() -> void:
	if not _is_edge_hanging:
		return
	velocity = Vector2.ZERO
	global_position = _get_ledge_hang_position()
	var input_snapshot := get_input_snapshot()
	var input_buffer := get_input_buffer()
	if input_snapshot == null:
		return
	if _edge_idle_input_guard_remaining <= 0.0 and input_snapshot.move_up_just_pressed:
		_log_edge("edge_idle_input up_pressed=true pos=%s" % str(global_position))
		_try_start_ledge_climb()
		return
	if input_buffer != null and input_buffer.has_buffered_jump():
		_log_edge("edge_idle_input buffered_jump=true pos=%s" % str(global_position))
		_perform_edge_idle_jump()
		return
	if input_snapshot.move_down_pressed or _is_pressing_away_from_ledge(input_snapshot.move_axis):
		_log_edge("edge_idle_release down=%s away=%s pos=%s" % [str(input_snapshot.move_down_pressed), str(_is_pressing_away_from_ledge(input_snapshot.move_axis)), str(global_position)])
		_release_edge_idle()


func _update_runtime_signals() -> void:
	if signals == null:
		return
	signals.is_grounded = is_on_floor()
	signals.is_invincible = _dash_time_remaining > 0.0 or _combat_invincible_remaining > 0.0
	if is_on_floor():
		_reset_air_jump_charges()
	elif is_on_wall_only():
		# 贴墙后刷新空中跳次数，让墙面成为明确的路线重置点，支持二段跳续航设计。
		_reset_air_jump_charges()
	_update_crouch_state_from_input()
	_update_swim_state()
	if _current_grapple_point != null and not is_instance_valid(_current_grapple_point):
		_current_grapple_point = null
	var wall_sliding_now := _is_wall_sliding()
	if _was_wall_sliding_last_frame and not wall_sliding_now:
		_log_wall("exit_slide vel_y=%.2f floor=%s wall=%s" % [velocity.y, str(is_on_floor()), str(is_on_wall_only())])
	_was_wall_sliding_last_frame = wall_sliding_now
	if _dash_time_remaining <= 0.0:
		_is_crouch_dashing = false
	_update_dash_collision_state()
	_update_dash_afterimage()
	_update_body_outline()
	_update_guard_outline()
	_update_player_visual_state()
	if signals.is_dead:
		return
	if _hurt_lock_remaining > 0.0:
		signals.current_action_tag = &"hurt"
		return
	if _is_shoot_aiming:
		signals.current_action_tag = &"shoot_aim"
		return
	if _attack_active_remaining > 0.0 or _attack_recovery_remaining > 0.0:
		signals.current_action_tag = _active_attack_action
		return
	if _is_guarding():
		signals.current_action_tag = &"guard"
		return
	var locomotion_state_machine := get_locomotion_state_machine()
	if locomotion_state_machine != null:
		signals.current_action_tag = locomotion_state_machine.get_current_state_id()


func _update_combat_input() -> void:
	var input_snapshot := get_input_snapshot()
	if input_snapshot == null:
		return
	if input_snapshot.guard_just_pressed:
		_parry_window_remaining = combat_profile.parry_window_ground if is_on_floor() else combat_profile.parry_window_air
	if input_snapshot.shoot_just_pressed:
		_try_begin_shoot_aim()
	if input_snapshot.shoot_just_released:
		_release_shoot_aim()
	if input_snapshot.attack_light_just_pressed:
		_try_start_light_attack()
	if input_snapshot.attack_heavy_just_pressed:
		_try_start_heavy_attack()


func _update_combat_runtime(_delta: float) -> void:
	_ensure_runtime_nodes()
	if _attack_hitbox == null:
		return
	_update_shoot_aim_state()
	_update_attack_hitbox_shape()
	_update_attack_hitbox_visual()
	if _attack_active_remaining > 0.0:
		_attack_hitbox.monitoring = true
		_process_attack_hits()
	else:
		_attack_hitbox.monitoring = false
		_attack_hit_ids.clear()


func _try_start_light_attack() -> void:
	if not _can_start_combat_action():
		return
	_attack_active_remaining = 0.12
	_attack_recovery_remaining = 0.24
	_attack_damage_scale = combat_profile.light_attack_damage_scale
	_active_attack_action = &"attack_light"
	_attack_hit_ids.clear()
	_last_combat_result = "attack_light"
	_last_attack_action = "attack_light"


func _try_start_heavy_attack() -> void:
	if not _can_start_combat_action():
		return
	_attack_active_remaining = 0.18
	_attack_recovery_remaining = 0.34
	_attack_damage_scale = combat_profile.heavy_attack_damage_scale
	_active_attack_action = &"attack_heavy"
	_attack_hit_ids.clear()
	_last_combat_result = "attack_heavy"
	_last_attack_action = "attack_heavy"


func _try_begin_shoot_aim() -> void:
	if not _can_start_combat_action():
		return
	_is_shoot_aiming = true
	_attack_active_remaining = 0.0
	_attack_recovery_remaining = 0.0
	_active_attack_action = &"shoot_aim"
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	_shoot_aim_direction = Vector2(facing, 0.0)
	_last_combat_result = "shoot_aim"


func _release_shoot_aim() -> void:
	if not _is_shoot_aiming:
		return
	_is_shoot_aiming = false
	_attack_recovery_remaining = 0.26
	_attack_damage_scale = combat_profile.shoot_damage_scale
	_active_attack_action = &"shoot"
	_attack_hit_ids.clear()
	_spawn_player_projectile()
	_last_combat_result = "shoot"
	_last_attack_action = "shoot"


func _can_start_combat_action() -> bool:
	if signals != null and not signals.can_accept_input:
		return false
	if _attack_recovery_remaining > 0.0 or _hurt_lock_remaining > 0.0:
		return false
	if is_grappling() or _is_swimming or _is_edge_hanging:
		return false
	return true


func _spawn_player_projectile() -> void:
	if PLAYER_PROJECTILE_SCENE == null:
		return
	var projectile := PLAYER_PROJECTILE_SCENE.instantiate() as ParryProjectile
	if projectile == null:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	parent_node.add_child(projectile)
	var shoot_direction := _get_shoot_direction()
	projectile.global_position = global_position + shoot_direction * 18.0
	projectile.set_owner_team(&"player")
	projectile.damage = (stats.get_attribute_value(&"attack_power", 10.0) if stats != null else 10.0) * combat_profile.shoot_damage_scale
	projectile.hitstun_duration = combat_profile.shoot_hitstun_duration
	var horizontal_sign := signf(shoot_direction.x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = float(signs_to_int(signals.facing_direction if signals != null else 1))
	projectile.knockback = Vector2(absf(combat_profile.shoot_knockback.x) * horizontal_sign, combat_profile.shoot_knockback.y)
	projectile.max_lifetime = combat_profile.shoot_projectile_lifetime
	projectile.velocity = shoot_direction * combat_profile.shoot_projectile_speed


func _process_attack_hits() -> void:
	for area in _attack_hitbox.get_overlapping_areas():
		if area == null or area == _hurtbox:
			continue
		var owner: Node = area.get_owner()
		if owner == null:
			owner = area.get_parent()
		if owner == null:
			continue
		var owner_id := owner.get_instance_id()
		if _attack_hit_ids.has(owner_id):
			continue
		if owner.has_method("receive_player_attack"):
			var knockback := _get_facing_knockback(combat_profile.light_attack_knockback)
			var stun_duration := combat_profile.light_attack_hitstun_duration
			if _active_attack_action == &"attack_heavy":
				knockback = _get_facing_knockback(combat_profile.heavy_attack_knockback)
				stun_duration = combat_profile.heavy_attack_hitstun_duration
			owner.receive_player_attack({
				"damage": (stats.get_attribute_value(&"attack_power", 10.0) if stats != null else 10.0) * _attack_damage_scale,
				"attack_kind": _active_attack_action,
				"source": self,
				"source_position": global_position,
				"knockback": knockback,
				"stun_duration": stun_duration,
			})
			_attack_hit_ids[owner_id] = true


func _update_attack_hitbox_shape() -> void:
	if _attack_hitbox_shape == null:
		return
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	var target_size := combat_profile.light_attack_hitbox_size
	var target_offset := combat_profile.light_attack_hitbox_offset
	if _active_attack_action == &"attack_heavy":
		target_size = combat_profile.heavy_attack_hitbox_size
		target_offset = combat_profile.heavy_attack_hitbox_offset
	var hitbox_shape := _attack_hitbox_shape.shape as RectangleShape2D
	if hitbox_shape != null:
		hitbox_shape.size = target_size
	$HitboxAnchor.position = Vector2(target_offset.x * facing, target_offset.y)


func _update_attack_hitbox_visual() -> void:
	var attack_hitbox_outline := _attack_hitbox as AreaDebugOutline
	if attack_hitbox_outline == null:
		return
	if _active_attack_action == &"attack_heavy":
		attack_hitbox_outline.outline_color = HEAVY_ATTACK_OUTLINE_COLOR
		return
	attack_hitbox_outline.outline_color = LIGHT_ATTACK_OUTLINE_COLOR


func _get_facing_knockback(base_knockback: Vector2) -> Vector2:
	var facing_sign := signf($HitboxAnchor.position.x)
	if is_zero_approx(facing_sign):
		facing_sign = float(signs_to_int(signals.facing_direction if signals != null else 1))
	return Vector2(absf(base_knockback.x) * facing_sign, base_knockback.y)


func _get_shoot_direction() -> Vector2:
	var input_snapshot := get_input_snapshot()
	if _is_shoot_aiming and _shoot_aim_direction.length() >= 0.1:
		return _shoot_aim_direction.normalized()
	if input_snapshot != null and input_snapshot.aim_vector.length() >= 0.35:
		return input_snapshot.aim_vector.normalized()
	if input_snapshot != null:
		var fallback_direction := Vector2(input_snapshot.move_axis, 0.0)
		if input_snapshot.move_up_pressed:
			fallback_direction.y = -1.0
		elif input_snapshot.move_down_pressed:
			fallback_direction.y = 1.0
		if fallback_direction.length() >= 0.1:
			return fallback_direction.normalized()
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	return Vector2(facing, 0.0)


func _update_shoot_aim_state() -> void:
	if not _is_shoot_aiming:
		if _aim_guide != null:
			_aim_guide.set_guide(false, Vector2.RIGHT)
		return
	_shoot_aim_direction = _resolve_hold_aim_direction()
	if _aim_guide != null:
		_aim_guide.set_guide(true, _shoot_aim_direction)


func _resolve_hold_aim_direction() -> Vector2:
	var input_snapshot := get_input_snapshot()
	if input_snapshot != null:
		var hold_direction := input_snapshot.move_vector
		if hold_direction.length() >= 0.1:
			return hold_direction.normalized()
		if input_snapshot.aim_vector.length() >= 0.35:
			return input_snapshot.aim_vector.normalized()
	if _shoot_aim_direction.length() >= 0.1:
		return _shoot_aim_direction.normalized()
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	return Vector2(facing, 0.0)


func receive_combat_hit(hit_data: Dictionary) -> DamageResult:
	var result: DamageResult = DamageResult.new()
	if signals != null and signals.is_dead:
		return result
	if _can_parry_hit(hit_data):
		return _handle_parry_hit(hit_data)
	if _can_chain_projectile_parry(hit_data):
		return _handle_projectile_parry_chain(hit_data)
	if _can_guard_hit(hit_data):
		return _handle_guard_hit(hit_data)
	result = damage_receiver.receive_hit(hit_data)
	if result.applied:
		_combat_invincible_remaining = combat_profile.hurt_invincible_duration
		_hurt_lock_remaining = 0.12
		_hurt_knockback_velocity = _get_hurt_knockback(hit_data)
		velocity = _hurt_knockback_velocity
		_last_combat_result = "hurt"
	return result


func _can_parry_hit(hit_data: Dictionary) -> bool:
	if _parry_window_remaining <= 0.0:
		return false
	if not bool(hit_data.get("can_be_parried", false)):
		return false
	return _is_front_facing_hit(hit_data)


func _can_chain_projectile_parry(hit_data: Dictionary) -> bool:
	if not bool(hit_data.get("is_projectile", false)):
		return false
	if _combat_invincible_remaining <= 0.0:
		return false
	if _last_combat_result != "projectile_parry":
		return false
	return _is_front_facing_hit(hit_data)


func _can_guard_hit(hit_data: Dictionary) -> bool:
	if not _is_guarding():
		return false
	return _is_front_facing_hit(hit_data)


func _is_front_facing_hit(hit_data: Dictionary) -> bool:
	var facing := Vector2(float(signs_to_int(signals.facing_direction if signals != null else 1)), 0.0)
	var source: Variant = hit_data.get("source")
	var source_position := global_position - facing * 999.0
	if source is Node2D:
		source_position = (source as Node2D).global_position
	elif hit_data.has("source_position"):
		source_position = hit_data.get("source_position")
	var to_source := source_position - global_position
	if to_source.length_squared() <= 0.001:
		return true
	# 这里统一用朝向和攻击源夹角做正反面判定，确保近战与飞行物都遵守同一套前方防御规则。
	var half_angle := deg_to_rad(combat_profile.guard_front_angle * 0.5)
	var min_dot := cos(half_angle)
	return facing.normalized().dot(to_source.normalized()) >= min_dot


func _handle_parry_hit(hit_data: Dictionary) -> DamageResult:
	var result: DamageResult = DamageResult.new()
	_parry_window_remaining = 0.0
	_combat_invincible_remaining = combat_profile.parry_invincible_duration
	if bool(hit_data.get("is_projectile", false)):
		_last_combat_result = "projectile_parry"
		_parry_flash_remaining = 0.14
		var projectile := hit_data.get("source") as ParryProjectile
		if projectile != null:
			var reflect_direction := _get_shoot_direction()
			projectile.reflect(reflect_direction, combat_profile.projectile_parry_speed_scale)
	else:
		var source: Variant = hit_data.get("source")
		if source != null and source.has_method("on_parried"):
			source.on_parried(combat_profile.parry_enemy_stun_duration)
		if is_on_floor():
			_last_combat_result = "ground_parry"
		else:
			_last_combat_result = "air_parry"
		_parry_flash_remaining = 0.14
	if not is_on_floor():
		velocity.y = -combat_profile.air_parry_bounce_velocity
	result.was_blocked_by_invincible = true
	return result


func _handle_projectile_parry_chain(hit_data: Dictionary) -> DamageResult:
	var result := DamageResult.new()
	_parry_flash_remaining = 0.14
	_last_combat_result = "projectile_parry"
	var projectile := hit_data.get("source") as ParryProjectile
	if projectile != null:
		var reflect_direction := _get_shoot_direction()
		projectile.reflect(reflect_direction, combat_profile.projectile_parry_speed_scale)
	result.was_blocked_by_invincible = true
	return result


func _handle_guard_hit(hit_data: Dictionary) -> DamageResult:
	var guarded_hit: Dictionary = hit_data.duplicate()
	guarded_hit["damage"] = float(hit_data.get("damage", 0.0)) * combat_profile.guard_chip_ratio
	var result: DamageResult = damage_receiver.receive_hit(guarded_hit)
	_last_combat_result = "guard"
	_hurt_lock_remaining = 0.05
	return result


func _is_guarding() -> bool:
	var input_snapshot := get_input_snapshot()
	if input_snapshot == null:
		return false
	if _hurt_lock_remaining > 0.0:
		return false
	return input_snapshot.guard_pressed


func _on_hurt_requested(_hit_data: Variant, _damage_result: DamageResult) -> void:
	_hurt_flash_remaining = 0.1
	_last_combat_result = "hurt"


func _on_death_requested(_damage_result: DamageResult) -> void:
	_hurt_flash_remaining = 0.0
	_hurt_knockback_velocity = Vector2.ZERO
	_dash_afterimage_remaining = 0.0
	if _sprite_root != null:
		var body_visual := _sprite_root.get_node_or_null("BodyVisual") as Polygon2D
		if body_visual != null:
			body_visual.color = Color(0.16, 0.16, 0.2, 1.0)
	_last_combat_result = "death"


func _update_player_visual_state() -> void:
	if _sprite_root == null:
		return
	var body_visual := _sprite_root.get_node_or_null("BodyVisual") as Polygon2D
	if body_visual == null:
		return
	if signals != null and signals.is_dead:
		body_visual.color = Color(0.16, 0.16, 0.2, 1.0)
		return
	if _dash_time_remaining > 0.0:
		body_visual.color = Color(0.72, 0.94, 1.0, 1.0)
		return
	if _hurt_flash_remaining > 0.0:
		body_visual.color = Color(1.0, 0.82, 0.56, 1.0)
		return
	body_visual.color = Color(0.294118, 0.686275, 0.901961, 1.0)


func _update_dash_collision_state() -> void:
	collision_mask = WORLD_COLLISION_MASK if _dash_time_remaining > 0.0 else PLAYER_DEFAULT_COLLISION_MASK


func _update_dash_afterimage() -> void:
	if _dash_time_remaining <= 0.0:
		_dash_afterimage_remaining = 0.0
		return
	if _dash_afterimage_remaining > 0.0:
		return
	_dash_afterimage_remaining = 0.045
	_spawn_dash_afterimage()


func _spawn_dash_afterimage() -> void:
	if _sprite_root == null or DASH_AFTERIMAGE_SCRIPT == null:
		return
	var body_visual := _sprite_root.get_node_or_null("BodyVisual") as Polygon2D
	if body_visual == null:
		return
	var afterimage := Polygon2D.new()
	afterimage.set_script(DASH_AFTERIMAGE_SCRIPT)
	afterimage.polygon = body_visual.polygon
	afterimage.color = Color(0.72, 0.94, 1.0, 0.55)
	afterimage.global_position = body_visual.global_position
	afterimage.global_rotation = body_visual.global_rotation
	afterimage.global_scale = body_visual.global_scale
	var parent_node := get_parent()
	if parent_node == null:
		return
	parent_node.add_child(afterimage)


func _update_body_outline() -> void:
	if _body_outline == null:
		return
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	_body_outline.set_facing_direction(facing)
	_body_outline.set_active(true)


func _update_guard_outline() -> void:
	if _guard_outline == null:
		return
	var guard_active := _is_guarding()
	var parry_flash_active := _parry_flash_remaining > 0.0
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	_guard_outline.set_facing_direction(facing)
	_guard_outline.set_active(guard_active or parry_flash_active)
	if parry_flash_active:
		_guard_outline.set_outline_color(Color(1.0, 0.9, 0.38, 1.0))
		return
	_guard_outline.set_outline_color(Color(0.4, 1.0, 0.82, 0.95))


func _get_hurt_knockback(hit_data: Dictionary) -> Vector2:
	var source_position := hit_data.get("source_position", global_position) as Vector2
	var horizontal_direction := signf(global_position.x - source_position.x)
	if is_zero_approx(horizontal_direction):
		horizontal_direction = -float(signs_to_int(signals.facing_direction if signals != null else 1))
	if bool(hit_data.get("is_projectile", false)):
		return Vector2(horizontal_direction * absf(combat_profile.hurt_knockback_projectile.x), combat_profile.hurt_knockback_projectile.y)
	return Vector2(horizontal_direction * absf(combat_profile.hurt_knockback_ground.x), combat_profile.hurt_knockback_ground.y)

func _can_jump() -> bool:
	if signals != null and not signals.can_accept_input:
		return false
	if _dash_time_remaining > 0.0:
		return false
	if _is_shoot_aiming:
		return false
	if is_grappling():
		return false
	if _is_swimming:
		return false
	if _is_edge_hanging:
		return false
	if _ledge_climb_remaining > 0.0:
		return false
	return _can_ground_jump() or _can_double_jump()


func _can_ground_jump() -> bool:
	if _is_crouching and _head_ray.is_colliding():
		return false
	return is_on_floor() or _coyote_time_remaining > 0.0


func _can_double_jump() -> bool:
	if not double_jump_unlocked:
		return false
	if is_on_floor():
		return false
	if _air_jumps_remaining <= 0:
		return false
	return not _can_wall_jump()


func _get_jump_failure_reason() -> String:
	if signals != null and not signals.can_accept_input:
		return "input_locked"
	if _dash_time_remaining > 0.0:
		return "during_dash"
	if is_grappling():
		return "during_grapple"
	if _is_swimming:
		return "during_swim"
	if _is_edge_hanging:
		return "during_edge_idle"
	if _ledge_climb_remaining > 0.0:
		return "during_edge_climb"
	if _is_crouching and _head_ray.is_colliding():
		return "head_blocked"
	if not double_jump_unlocked and not is_on_floor():
		return "double_jump_locked"
	if not is_on_floor() and _air_jumps_remaining <= 0:
		return "no_air_jump"
	return "no_floor_or_coyote"


func _can_wall_jump() -> bool:
	return controller != null and controller.wall_detector.can_wall_jump(self)


func _can_dash() -> bool:
	if signals != null and not signals.can_accept_input:
		return false
	if is_grappling():
		return false
	if _is_shoot_aiming:
		return false
	if _is_swimming:
		return false
	if _is_edge_hanging:
		return false
	if _ledge_climb_remaining > 0.0:
		return false
	if _is_crouching and not is_on_floor():
		return false
	return _dash_time_remaining <= 0.0 and _dash_cooldown_remaining <= 0.0


func _get_dash_failure_reason() -> String:
	if signals != null and not signals.can_accept_input:
		return "input_locked"
	if _ledge_climb_remaining > 0.0:
		return "during_edge_climb"
	if is_grappling():
		return "during_grapple"
	if _is_swimming:
		return "during_swim"
	if _is_edge_hanging:
		return "during_edge_idle"
	if _dash_time_remaining > 0.0:
		return "during_dash"
	if _dash_cooldown_remaining > 0.0:
		return "cooldown"
	return "unknown"


func _update_crouch_state_from_input() -> void:
	if _is_crouch_dashing:
		return
	if _is_shoot_aiming:
		_exit_crouch_if_possible(true)
		return
	if _is_swimming:
		_exit_crouch_if_possible(true)
		return
	if not is_on_floor():
		_exit_crouch_if_possible(true)
		return
	var input_snapshot := get_input_snapshot()
	var wants_crouch := input_snapshot != null and input_snapshot.move_down_pressed
	if wants_crouch:
		_enter_crouch()
	else:
		_exit_crouch_if_possible(false)


func _enter_crouch() -> void:
	if _is_swimming:
		return
	if _is_crouching:
		return
	_update_crouch_collision(true)
	_is_crouching = true


func _exit_crouch_if_possible(force: bool) -> void:
	if not _is_crouching:
		return
	if not force and not _has_standing_headroom():
		return
	_update_crouch_collision(false)
	_is_crouching = false


func _has_standing_headroom() -> bool:
	_ensure_runtime_nodes()
	if _body_shape == null:
		return false
	var current_shape := _body_shape.shape as RectangleShape2D
	if current_shape == null:
		return false
	var test_shape := RectangleShape2D.new()
	test_shape.size = Vector2(current_shape.size.x, motion_profile.standing_collision_height)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = test_shape
	query.transform = Transform2D(0.0, global_position)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# 这里不再依赖短射线判断站起空间，而是直接用“站立碰撞体”做一次空间查询，
	# 避免在低矮通道里松开下键后误判可站立，导致角色强行顶天花板站起。
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	return space_state.intersect_shape(query, 1).is_empty()


func _update_crouch_collision(crouched: bool) -> void:
	_ensure_runtime_nodes()
	var target_height := motion_profile.crouch_collision_height if crouched else motion_profile.standing_collision_height
	if _body_shape == null or _hurtbox_shape == null:
		push_warning("PlayerTestActor could not resolve collision shapes for crouch update.")
		return
	var body_shape := _body_shape.shape as RectangleShape2D
	if body_shape != null:
		body_shape.size.y = target_height
		_body_shape.position.y = (motion_profile.standing_collision_height - target_height) * 0.5
	var hurtbox_shape := _hurtbox_shape.shape as RectangleShape2D
	if hurtbox_shape != null:
		hurtbox_shape.size.y = target_height
		_hurtbox_shape.position.y = (motion_profile.standing_collision_height - target_height) * 0.5
	if _sprite_root != null:
		_sprite_root.position.y = (motion_profile.standing_collision_height - target_height) * 0.5


func _reset_air_jump_charges() -> void:
	_air_jumps_remaining = motion_profile.max_air_jumps if double_jump_unlocked else 0


func _should_crouch_dash() -> bool:
	return _is_crouching and is_on_floor()


func _update_swim_state() -> void:
	if is_grappling():
		_is_swimming = false
		return
	if not _is_in_deep_water:
		_is_swimming = false
		return
	if not swim_unlocked:
		_is_swimming = false
		return
	if _is_edge_hanging or _ledge_climb_remaining > 0.0:
		_is_swimming = false
		return
	_is_swimming = true
	if signals != null and signals.current_action_tag != &"swim":
		signals.current_action_tag = &"swim"


func on_water_volume_entered(water_mode: StringName, requires_unlock: bool, respawn_position: Vector2) -> void:
	if water_mode == &"shallow":
		_is_in_shallow_water = true
		_last_swim_failure_reason = "shallow_water"
		return
	if water_mode != &"deep":
		return
	_is_in_deep_water = true
	_exit_crouch_if_possible(true)
	_exit_edge_idle(false)
	if requires_unlock and not swim_unlocked:
		_handle_locked_water(respawn_position)
		return
	_last_swim_failure_reason = "entered_swim"
	_update_swim_state()


func on_water_volume_exited(water_mode: StringName) -> void:
	if water_mode == &"shallow":
		_is_in_shallow_water = false
		return
	if water_mode != &"deep":
		return
	var was_swimming := _is_swimming
	_is_in_deep_water = false
	_is_swimming = false
	if was_swimming and velocity.y < 0.0:
		velocity.y = minf(velocity.y, -motion_profile.swim_surface_exit_boost)
	_last_swim_failure_reason = "exited_swim"


func _handle_locked_water(respawn_position: Vector2) -> void:
	_is_in_deep_water = false
	_is_swimming = false
	velocity = Vector2.ZERO
	_last_swim_failure_reason = "swim_locked"
	if respawn_position != Vector2.ZERO:
		global_position = respawn_position


func _can_enter_edge_idle() -> bool:
	if controller == null:
		return false
	if _ledge_regrab_lock_remaining > 0.0:
		return false
	if _dash_time_remaining > 0.0:
		return false
	if velocity.y < 0.0:
		return false
	return controller.ledge_detector.can_ledge_climb(self, _head_ray, _ledge_ray_forward, _ledge_ray_down, _dash_time_remaining)


func _release_edge_idle() -> void:
	_exit_edge_idle(true)
	_ledge_regrab_lock_remaining = 0.14
	velocity.y = maxf(velocity.y, 80.0)
	if signals != null:
		signals.current_action_tag = &"fall"


func _exit_edge_idle(start_regrab_lock: bool) -> void:
	if not _is_edge_hanging:
		return
	_is_edge_hanging = false
	if start_regrab_lock:
		_ledge_regrab_lock_remaining = 0.14


func _perform_edge_idle_jump() -> void:
	var input_buffer := get_input_buffer()
	var locomotion_motor := get_locomotion_motor()
	if input_buffer == null or locomotion_motor == null:
		return
	if not input_buffer.consume_jump():
		return
	_exit_edge_idle(true)
	_wall_jump_input_lock_remaining = motion_profile.wall_jump_input_lock_time
	var horizontal_speed := -float(signs_to_int(signals.facing_direction if signals != null else 1)) * motion_profile.wall_jump_horizontal_speed
	locomotion_motor.apply_wall_jump_velocity(self, horizontal_speed, motion_profile.wall_jump_vertical_speed)
	context.set_facing_direction(sign(horizontal_speed))
	if signals != null:
		signals.is_grounded = false
		signals.current_action_tag = &"wall_jump"
	_last_jump_failure_reason = "edge_jump"


func _is_pressing_away_from_ledge(input_axis: float) -> bool:
	if is_zero_approx(input_axis):
		return false
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	return sign(input_axis) == -facing


func _is_wall_sliding() -> bool:
	return controller != null and controller.wall_detector.is_wall_sliding(self)


func is_wall_sliding() -> bool:
	return _is_wall_sliding()


func is_dashing() -> bool:
	return _dash_time_remaining > 0.0 and not _is_crouch_dashing


func is_crouch_dashing() -> bool:
	return _dash_time_remaining > 0.0 and _is_crouch_dashing


func is_edge_climbing() -> bool:
	return _ledge_climb_remaining > 0.0


func is_grappling() -> bool:
	return _current_grapple_point != null or _grapple_release_remaining > 0.0


func is_edge_hanging() -> bool:
	return _is_edge_hanging


func is_swimming() -> bool:
	return _is_swimming


func is_wall_jumping() -> bool:
	return _wall_jump_input_lock_remaining > 0.0 and not is_on_floor()


func is_double_jumping() -> bool:
	return _double_jump_state_remaining > 0.0 and not is_on_floor()


func is_crouching() -> bool:
	return _is_crouching


func has_crouch_move_input() -> bool:
	var input_snapshot := get_input_snapshot()
	return input_snapshot != null and absf(input_snapshot.move_axis) > 0.1


func get_dash_time_remaining() -> float:
	return _dash_time_remaining


func get_coyote_time_remaining() -> float:
	return _coyote_time_remaining


func get_last_jump_failure_reason() -> String:
	return _last_jump_failure_reason


func get_last_dash_failure_reason() -> String:
	return _last_dash_failure_reason


func get_last_swim_failure_reason() -> String:
	return _last_swim_failure_reason


func get_last_grapple_failure_reason() -> String:
	return _last_grapple_failure_reason


func get_last_combat_result() -> String:
	return _last_combat_result


func reset_for_testroom(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
	if stats != null:
		stats.apply_respawn_resource_values()
	if signals != null:
		signals.is_dead = false
		signals.can_accept_input = true
		signals.is_invincible = false
		signals.current_action_tag = &"idle"
	_dash_time_remaining = 0.0
	_dash_cooldown_remaining = 0.0
	_wall_jump_input_lock_remaining = 0.0
	_ledge_climb_remaining = 0.0
	_ledge_regrab_lock_remaining = 0.0
	_edge_idle_input_guard_remaining = 0.0
	_grapple_min_remaining = 0.0
	_grapple_release_remaining = 0.0
	_parry_window_remaining = 0.0
	_combat_invincible_remaining = 0.0
	_attack_active_remaining = 0.0
	_attack_recovery_remaining = 0.0
	_hurt_lock_remaining = 0.0
	_hurt_flash_remaining = 0.0
	_dash_afterimage_remaining = 0.0
	_parry_flash_remaining = 0.0
	_is_shoot_aiming = false
	_attack_hit_ids.clear()
	_current_grapple_point = null
	_is_edge_hanging = false
	_is_swimming = false
	_last_combat_result = "ready"
	_last_attack_action = "none"
	_reset_air_jump_charges()


func get_last_attack_action() -> String:
	return _last_attack_action


func get_parry_window_remaining() -> float:
	return _parry_window_remaining


func is_guarding() -> bool:
	return _is_guarding()


func is_ability_unlocked(ability_name: StringName) -> bool:
	match ability_name:
		&"double_jump":
			return double_jump_unlocked
		&"swim":
			return swim_unlocked
		&"grapple":
			return grapple_unlocked
		_:
			return false


func toggle_ability_unlock(ability_name: StringName) -> void:
	match ability_name:
		&"double_jump":
			double_jump_unlocked = not double_jump_unlocked
			_reset_air_jump_charges()
		&"swim":
			swim_unlocked = not swim_unlocked
			if not swim_unlocked:
				_is_swimming = false
		&"grapple":
			grapple_unlocked = not grapple_unlocked
			if not grapple_unlocked:
				_release_grapple("grapple_locked")


func get_air_jumps_remaining() -> int:
	return _air_jumps_remaining


func _apply_corner_correction() -> void:
	if velocity.y >= 0.0:
		return
	if is_on_wall_only():
		return
	if not _head_ray.is_colliding():
		return
	var facing := signs_to_int(signals.facing_direction if signals != null else 1)
	var correction := float(facing) * motion_profile.corner_correction_distance
	var test_transform := global_transform.translated(Vector2(correction, 0.0))
	if test_move(test_transform, Vector2.ZERO):
		return
	global_position.x += correction


func _can_ledge_climb() -> bool:
	if controller == null:
		return false
	return controller.ledge_detector.can_ledge_climb(self, _head_ray, _ledge_ray_forward, _ledge_ray_down, _dash_time_remaining)


func _get_ledge_snap_position() -> Vector2:
	if controller == null:
		return global_position
	var facing := signs_to_int(signals.facing_direction if signals != null else 1)
	return controller.ledge_detector.get_snap_position(_ledge_ray_down, facing)


func _get_ledge_point() -> Vector2:
	if controller == null:
		return Vector2.ZERO
	return controller.ledge_detector.get_ledge_point(_ledge_ray_down)


func _get_ledge_hang_position() -> Vector2:
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	var hang_center_y := _ledge_top_point.y + motion_profile.standing_collision_height * 0.5
	var hang_center_x := _ledge_top_point.x - 16.0 * facing
	return Vector2(hang_center_x, hang_center_y)


func should_skip_motion_commit() -> bool:
	return _is_edge_hanging


func _get_ledge_climb_position() -> Vector2:
	var facing := float(signs_to_int(signals.facing_direction if signals != null else 1))
	return Vector2(_ledge_top_point.x - 12.0 * facing, _ledge_top_point.y - motion_profile.standing_collision_height * 0.5)


func signs_to_int(value: int) -> int:
	return 1 if value >= 0 else -1

func _can_grapple() -> bool:
	if signals != null and not signals.can_accept_input:
		return false
	if not grapple_unlocked:
		return false
	if is_on_floor():
		return false
	if _is_swimming or _is_edge_hanging or _ledge_climb_remaining > 0.0:
		return false
	return _current_grapple_point == null


func _get_grapple_failure_reason() -> String:
	if signals != null and not signals.can_accept_input:
		return "input_locked"
	if not grapple_unlocked:
		return "grapple_locked"
	if is_on_floor():
		return "grounded"
	if _is_swimming:
		return "during_swim"
	if _is_edge_hanging:
		return "during_edge_idle"
	if _ledge_climb_remaining > 0.0:
		return "during_edge_climb"
	if _current_grapple_point != null:
		return "during_grapple"
	return "no_point"


func _find_best_grapple_point() -> GrapplePoint:
	var best_point: GrapplePoint = null
	var best_distance := INF
	var facing := Vector2(float(signs_to_int(signals.facing_direction if signals != null else 1)), 0.0)
	for node in get_tree().get_nodes_in_group("grapple_points"):
		if not node is GrapplePoint:
			continue
		var grapple_point := node as GrapplePoint
		if not is_instance_valid(grapple_point) or not grapple_point.can_grapple():
			continue
		var to_point := grapple_point.global_position - global_position
		var distance := to_point.length()
		if distance > motion_profile.grapple_search_radius:
			continue
		if to_point == Vector2.ZERO:
			continue
		var angle := rad_to_deg(acos(clampf(facing.normalized().dot(to_point.normalized()), -1.0, 1.0)))
		if angle > motion_profile.grapple_snap_angle:
			continue
		if distance < best_distance:
			best_distance = distance
			best_point = grapple_point
	return best_point


func _release_grapple(reason: String) -> void:
	if _current_grapple_point == null:
		return
	var target_point := _current_grapple_point.global_position if is_instance_valid(_current_grapple_point) else global_position
	var release_direction := (target_point - global_position).normalized()
	_current_grapple_point = null
	_grapple_initial_distance = 0.0
	_grapple_release_remaining = motion_profile.grapple_release_duration
	if release_direction != Vector2.ZERO and velocity.length() < motion_profile.grapple_release_boost:
		velocity = release_direction * motion_profile.grapple_release_boost
	# 这里在到点时保留穿点惯性，再用短时间高减速度收尾，让角色穿过钩点后自然减速而不是瞬停。
	_last_grapple_failure_reason = reason
	if signals != null:
		signals.current_action_tag = &"fall"
