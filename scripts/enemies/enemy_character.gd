class_name EnemyCharacter
extends CharacterBody2D


@export var combat_profile: CharacterCombatProfile
@export var motion_profile: CharacterMotionProfile
@export var player_path: NodePath
@export var projectile_scene: PackedScene
@export var contact_damage: float = 14.0
@export var projectile_damage: float = 12.0
@export var respawn_delay: float = 1.25
@export var aggro_range: float = 420.0
@export var melee_range: float = 72.0
@export var preferred_range: float = 180.0


var stats: CharacterStats = CharacterStats.new()
var signals: CharacterSignals = CharacterSignals.new()
var context: CharacterContext = CharacterContext.new()
var damage_receiver: DamageReceiver = DamageReceiver.new()
var ai_controller: EnemyAiController = EnemyAiController.new()

var _stun_remaining: float = 0.0
var _attack_cycle_remaining: float = 0.9
var _projectile_cycle_remaining: float = 1.8
var _attack_active_remaining: float = 0.0
var _hurt_flash_remaining: float = 0.0
var _respawn_remaining: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _attack_area: Area2D = $AttackArea
@onready var _body_visual: Polygon2D = $SpriteRoot/BodyVisual
@onready var _projectile_spawn: Marker2D = $ProjectileSpawn


func _ready() -> void:
	_spawn_position = global_position
	if combat_profile == null:
		combat_profile = CharacterCombatProfile.new()
	if motion_profile == null:
		motion_profile = CharacterMotionProfile.new()
	ai_controller.configure(aggro_range, melee_range, preferred_range)
	stats.configure_from_profile(combat_profile)
	context.setup(self, stats, signals, combat_profile, motion_profile)
	damage_receiver.setup(context)
	damage_receiver.hurt_requested.connect(_on_hurt_requested)
	damage_receiver.death_requested.connect(_on_death_requested)
	_attack_area.monitoring = false
	_attack_area.body_entered.connect(_on_attack_area_body_entered)


func _physics_process(delta: float) -> void:
	if signals.is_dead:
		_respawn_remaining = maxf(0.0, _respawn_remaining - delta)
		if _respawn_remaining <= 0.0:
			respawn_at(_spawn_position)
		return
	_update_timers(delta)
	_apply_gravity(delta)
	_update_facing()
	_update_attack_nodes()
	if _stun_remaining <= 0.0:
		_run_ai(delta)
	else:
		velocity.x = _knockback_velocity.x
		if _knockback_velocity.y < velocity.y:
			velocity.y = _knockback_velocity.y
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 880.0 * delta)
	move_and_slide()
	if is_on_floor() and velocity.y > 0.0:
		velocity.y = 0.0
	signals.is_grounded = is_on_floor()
	_update_visual_state()


func receive_player_attack(hit_data: Dictionary) -> DamageResult:
	var result: DamageResult = damage_receiver.receive_hit(hit_data)
	if result.applied:
		_stun_remaining = maxf(_stun_remaining, float(hit_data.get("stun_duration", _get_default_stun_duration(hit_data))))
		_knockback_velocity = hit_data.get("knockback", _get_default_knockback(hit_data)) as Vector2
		velocity = _knockback_velocity
		_hurt_flash_remaining = 0.08
		signals.current_action_tag = &"enemy_hit"
	return result


func respawn_at(target_position: Vector2) -> void:
	global_position = target_position
	_spawn_position = target_position
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	stats.current_hp = stats.max_hp
	signals.is_dead = false
	signals.can_accept_input = true
	signals.is_invincible = false
	signals.current_action_tag = &"enemy_idle"
	_stun_remaining = 0.0
	_attack_cycle_remaining = 0.4
	_projectile_cycle_remaining = 1.0
	_attack_active_remaining = 0.0
	_hurt_flash_remaining = 0.0
	_respawn_remaining = 0.0
	_attack_area.monitoring = false


func on_parried(stun_duration: float) -> void:
	_stun_remaining = maxf(_stun_remaining, stun_duration)
	_attack_active_remaining = 0.0
	_attack_area.monitoring = false
	signals.current_action_tag = &"enemy_parried"


func _update_timers(delta: float) -> void:
	_stun_remaining = maxf(0.0, _stun_remaining - delta)
	_attack_cycle_remaining = maxf(0.0, _attack_cycle_remaining - delta)
	_projectile_cycle_remaining = maxf(0.0, _projectile_cycle_remaining - delta)
	_attack_active_remaining = maxf(0.0, _attack_active_remaining - delta)
	_hurt_flash_remaining = maxf(0.0, _hurt_flash_remaining - delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += motion_profile.gravity_down * delta


func _update_facing() -> void:
	var player := _get_player()
	if player == null:
		return
	var delta_x := player.global_position.x - global_position.x
	if is_zero_approx(delta_x):
		return
	context.set_facing_direction(1 if delta_x >= 0.0 else -1)


func _update_attack_nodes() -> void:
	var facing := float(signi(signals.facing_direction))
	_attack_area.position.x = 22.0 * facing
	_projectile_spawn.position.x = 18.0 * facing
	_attack_area.monitoring = _attack_active_remaining > 0.0 and _stun_remaining <= 0.0


func _run_ai(delta: float) -> void:
	var player := _get_player()
	var decision := ai_controller.evaluate(global_position, player, velocity.x, motion_profile, _attack_cycle_remaining, _projectile_cycle_remaining, delta)
	velocity.x = float(decision.get("velocity_x", 0.0))
	if bool(decision.get("start_melee", false)):
		_try_start_melee_attack()
		return
	if bool(decision.get("start_projectile", false)) and player != null:
		_try_fire_projectile(player)
		return
	signals.current_action_tag = decision.get("action_tag", &"enemy_idle")


func _try_start_melee_attack() -> void:
	_attack_cycle_remaining = 1.35
	_attack_active_remaining = 0.14
	velocity.x = 0.0
	signals.current_action_tag = &"enemy_attack"


func _try_fire_projectile(player: Node2D) -> void:
	if projectile_scene == null:
		return
	_projectile_cycle_remaining = 2.4
	var projectile := projectile_scene.instantiate() as ParryProjectile
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = _projectile_spawn.global_position
	projectile.owner_team = &"enemy"
	projectile.damage = projectile_damage
	projectile.hitstun_duration = combat_profile.shoot_hitstun_duration
	projectile.knockback = combat_profile.shoot_knockback
	projectile.max_lifetime = combat_profile.shoot_projectile_lifetime
	projectile.velocity = (_get_projectile_target(player) - _projectile_spawn.global_position).normalized() * combat_profile.shoot_projectile_speed
	velocity.x = 0.0
	signals.current_action_tag = &"enemy_projectile"


func _get_projectile_target(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0.0, -8.0)


func _get_player() -> Node2D:
	return get_node_or_null(player_path) as Node2D


func _on_attack_area_body_entered(body: Node) -> void:
	if not body is PlayerTestActor:
		return
	var actor := body as PlayerTestActor
	if actor.is_dashing() or actor.is_crouch_dashing():
		return
	actor.receive_combat_hit({
		"damage": contact_damage,
		"attack_kind": &"melee",
		"can_be_parried": true,
		"source": self,
		"source_position": global_position,
	})


func _update_visual_state() -> void:
	if _stun_remaining > 0.0:
		_body_visual.color = Color(1.0, 0.78, 0.38, 1.0) if _hurt_flash_remaining > 0.0 else Color(0.964706, 0.682353, 0.352941, 1.0)
		return
	if signals.is_dead:
		_body_visual.color = Color(0.18, 0.18, 0.18, 1.0)
		return
	_body_visual.color = Color(1.0, 0.8, 0.5, 1.0) if _hurt_flash_remaining > 0.0 else Color(0.823529, 0.380392, 0.380392, 1.0)


func _get_default_stun_duration(hit_data: Dictionary) -> float:
	match StringName(hit_data.get("attack_kind", &"light_attack")):
		&"attack_heavy":
			return combat_profile.heavy_attack_hitstun_duration
		&"shoot":
			return combat_profile.shoot_hitstun_duration
		_:
			return combat_profile.light_attack_hitstun_duration


func _get_default_knockback(hit_data: Dictionary) -> Vector2:
	var source_position := hit_data.get("source_position", global_position) as Vector2
	var horizontal_direction := signf(global_position.x - source_position.x)
	if is_zero_approx(horizontal_direction):
		horizontal_direction = -float(signi(signals.facing_direction))
	match StringName(hit_data.get("attack_kind", &"light_attack")):
		&"attack_heavy":
			return Vector2(horizontal_direction * absf(combat_profile.heavy_attack_knockback.x), combat_profile.heavy_attack_knockback.y)
		&"shoot":
			return Vector2(horizontal_direction * absf(combat_profile.shoot_knockback.x), combat_profile.shoot_knockback.y)
		_:
			return Vector2(horizontal_direction * absf(combat_profile.light_attack_knockback.x), combat_profile.light_attack_knockback.y)


func _on_hurt_requested(_hit_data: Variant, _damage_result: DamageResult) -> void:
	_hurt_flash_remaining = 0.08


func _on_death_requested(_damage_result: DamageResult) -> void:
	signals.is_dead = true
	signals.can_accept_input = false
	_respawn_remaining = respawn_delay
	_attack_active_remaining = 0.0
	_attack_area.monitoring = false
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_body_visual.color = Color(0.18, 0.18, 0.18, 1.0)
