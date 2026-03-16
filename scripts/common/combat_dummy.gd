class_name CombatDummy
extends Node2D


const COMBAT_CHASE_POINT_SCRIPT := preload("res://scripts/common/combat_chase_point.gd")


@export var combat_profile: CharacterCombatProfile
@export var attributes_profile: Resource
@export var player_path: NodePath
@export var projectile_scene: PackedScene
@export var contact_damage: float = 14.0
@export var projectile_damage: float = 12.0
@export var respawn_delay: float = 1.25
@export var combo_reaction_category: StringName = &"humanoid_small"
@export var floor_y: float = 0.0
@export var gravity: float = 900.0
@export var hover_in_place: bool = false

var stats: CharacterStats = CharacterStats.new()
var signals: CharacterSignals = CharacterSignals.new()
var context: CharacterContext = CharacterContext.new()
var damage_receiver: DamageReceiver = DamageReceiver.new()
var _stun_remaining: float = 0.0
var _attack_cycle_remaining: float = 0.9
var _projectile_cycle_remaining: float = 1.8
var _attack_active_remaining: float = 0.0
var _hurt_flash_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _respawn_remaining: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _combat_chase_point: GrapplePoint = null
var _vertical_velocity: float = 0.0
var _status_text_remaining: float = 0.0

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _attack_area: Area2D = $AttackArea
@onready var _body_visual: Polygon2D = $BodyVisual
@onready var _projectile_spawn: Marker2D = $ProjectileSpawn
@onready var _status_label: Label = $StatusLabel


func _ready() -> void:
	_spawn_position = global_position
	if is_zero_approx(floor_y) and not hover_in_place:
		floor_y = _spawn_position.y
	if combat_profile == null:
		combat_profile = CharacterCombatProfile.new()
	if attributes_profile != null:
		stats.configure_from_attributes_profile(attributes_profile)
	else:
		stats.configure_from_profile(combat_profile)
	context.setup(self, stats, signals, combat_profile, null, null, attributes_profile, stats.attribute_set)
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
	_stun_remaining = maxf(0.0, _stun_remaining - delta)
	_attack_cycle_remaining = maxf(0.0, _attack_cycle_remaining - delta)
	_projectile_cycle_remaining = maxf(0.0, _projectile_cycle_remaining - delta)
	_attack_active_remaining = maxf(0.0, _attack_active_remaining - delta)
	_hurt_flash_remaining = maxf(0.0, _hurt_flash_remaining - delta)
	_status_text_remaining = maxf(0.0, _status_text_remaining - delta)
	_apply_gravity(delta)
	global_position += Vector2(_knockback_velocity.x, _knockback_velocity.y + _vertical_velocity) * delta
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	if not hover_in_place and global_position.y >= floor_y:
		global_position.y = floor_y
		_vertical_velocity = 0.0
		if _knockback_velocity.y > 0.0:
			_knockback_velocity.y = 0.0
	_attack_area.monitoring = _attack_active_remaining > 0.0 and _stun_remaining <= 0.0
	_attack_area.position.x = -22.0 * float(signi(signals.facing_direction))
	_projectile_spawn.position.x = -18.0 * float(signi(signals.facing_direction))
	_update_status_label()
	if _stun_remaining > 0.0:
		signals.current_action_tag = &"enemy_stun"
		_body_visual.color = Color(1.0, 0.78, 0.38, 1.0) if _hurt_flash_remaining > 0.0 else Color(0.964706, 0.682353, 0.352941, 1)
		return
	_body_visual.color = Color(1.0, 0.8, 0.5, 1.0) if _hurt_flash_remaining > 0.0 else Color(0.823529, 0.380392, 0.380392, 1)
	_signals_from_player_position()
	if _attack_cycle_remaining <= 0.0:
		_try_start_melee_attack()
	if _projectile_cycle_remaining <= 0.0:
		_try_fire_projectile()


func receive_player_attack(hit_data: Dictionary) -> DamageResult:
	var result: DamageResult = damage_receiver.receive_hit(hit_data)
	if result.applied:
		_stun_remaining = maxf(_stun_remaining, float(hit_data.get("stun_duration", _get_default_stun_duration(hit_data))))
		_knockback_velocity = hit_data.get("knockback", _get_default_knockback(hit_data)) as Vector2
		_hurt_flash_remaining = 0.08
		signals.current_action_tag = &"enemy_hit"
		_apply_combo_reaction(hit_data)
	return result


func get_combo_reaction_context() -> Dictionary:
	return {
		"category": combo_reaction_category,
		"has_super_armor": signals.has_super_armor if signals != null else false,
	}


func has_active_combat_chase_point() -> bool:
	return _combat_chase_point != null and is_instance_valid(_combat_chase_point) and _combat_chase_point.can_grapple()


func respawn_at(target_position: Vector2) -> void:
	global_position = target_position
	_spawn_position = target_position
	stats.apply_respawn_resource_values()
	signals.is_dead = false
	signals.can_accept_input = true
	signals.is_invincible = false
	_stun_remaining = 0.0
	_attack_cycle_remaining = 0.4
	_projectile_cycle_remaining = 1.0
	_attack_active_remaining = 0.0
	_hurt_flash_remaining = 0.0
	_knockback_velocity = Vector2.ZERO
	_vertical_velocity = 0.0
	_respawn_remaining = 0.0
	_attack_area.monitoring = false
	_body_visual.color = Color(0.823529, 0.380392, 0.380392, 1)
	signals.current_action_tag = &"enemy_idle"
	_clear_combat_chase_point()


func on_parried(stun_duration: float) -> void:
	_stun_remaining = maxf(_stun_remaining, stun_duration)
	_attack_active_remaining = 0.0
	_attack_area.monitoring = false
	signals.current_action_tag = &"enemy_parried"


func _apply_combo_reaction(hit_data: Dictionary) -> void:
	var combo_reaction := StringName(hit_data.get("combo_reaction", &""))
	match combo_reaction:
		&"knockdown":
			_stun_remaining = maxf(_stun_remaining, 0.72)
			_knockback_velocity = Vector2(_knockback_velocity.x * 0.6, minf(_knockback_velocity.y, -120.0))
			_show_status_text("KNOCKDOWN")
			signals.current_action_tag = &"enemy_knockdown"
		&"launcher":
			_stun_remaining = maxf(_stun_remaining, 0.74)
			_knockback_velocity = Vector2(signf(_knockback_velocity.x) * maxf(absf(_knockback_velocity.x), 220.0), minf(_knockback_velocity.y, -245.0))
			_vertical_velocity = minf(_vertical_velocity, -210.0)
			_show_status_text("LAUNCHER")
			signals.current_action_tag = &"enemy_launcher"
		&"air_chase_launch":
			_stun_remaining = maxf(_stun_remaining, 0.46)
			_knockback_velocity = Vector2(_knockback_velocity.x * 1.15, maxf(_knockback_velocity.y, 280.0))
			_vertical_velocity = 0.0
			_hurt_flash_remaining = maxf(_hurt_flash_remaining, 0.16)
			_spawn_combat_chase_point()
			_show_status_text("CHASE BREAK")
			signals.current_action_tag = &"enemy_air_launch"
		&"air_juggle":
			_stun_remaining = maxf(_stun_remaining, 0.38)
			_knockback_velocity = Vector2(0.0, minf(_knockback_velocity.y, -145.0))
			_vertical_velocity = minf(_vertical_velocity, -135.0)
			_show_status_text("JUGGLE")
			signals.current_action_tag = &"enemy_air_juggle"
		&"heavy_stagger":
			_stun_remaining = maxf(_stun_remaining, 0.42)
			_knockback_velocity = Vector2(_knockback_velocity.x * 0.5, _knockback_velocity.y)
			_show_status_text("STAGGER")
			signals.current_action_tag = &"enemy_heavy_stagger"
		&"resisted":
			_stun_remaining = maxf(_stun_remaining, 0.12)
			_knockback_velocity = Vector2(_knockback_velocity.x * 0.25, _knockback_velocity.y)
			_show_status_text("RESIST")
			signals.current_action_tag = &"enemy_resisted"


func _spawn_combat_chase_point() -> void:
	_clear_combat_chase_point()
	if COMBAT_CHASE_POINT_SCRIPT == null or get_parent() == null:
		return
	var chase_point := COMBAT_CHASE_POINT_SCRIPT.new()
	if chase_point == null:
		return
	get_parent().add_child(chase_point)
	chase_point.setup(self, Vector2(0.0, -12.0), 0.7)
	_combat_chase_point = chase_point


func _clear_combat_chase_point() -> void:
	if _combat_chase_point != null and is_instance_valid(_combat_chase_point):
		_combat_chase_point.queue_free()
	_combat_chase_point = null


func _signals_from_player_position() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if player == null:
		return
	var delta_x := player.global_position.x - global_position.x
	signals.facing_direction = 1 if delta_x >= 0.0 else -1


func _try_start_melee_attack() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if player == null:
		return
	if global_position.distance_to(player.global_position) > 76.0:
		return
	_attack_cycle_remaining = 1.35
	_attack_active_remaining = 0.14
	signals.current_action_tag = &"enemy_attack"


func _try_fire_projectile() -> void:
	if projectile_scene == null:
		return
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if player == null:
		return
	_projectile_cycle_remaining = 2.4
	var projectile: ParryProjectile = projectile_scene.instantiate() as ParryProjectile
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = _projectile_spawn.global_position
	projectile.owner_team = &"enemy"
	projectile.damage = projectile_damage
	projectile.hitstun_duration = combat_profile.shoot_hitstun_duration
	projectile.knockback = combat_profile.shoot_knockback
	projectile.velocity = (_get_projectile_target(player) - _projectile_spawn.global_position).normalized() * 220.0
	signals.current_action_tag = &"enemy_projectile"


func _get_projectile_target(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0.0, -8.0)


func _on_attack_area_body_entered(body: Node) -> void:
	if not body is PlayerTestActor:
		return
	var actor: PlayerTestActor = body as PlayerTestActor
	actor.receive_combat_hit({
		"damage": contact_damage,
		"attack_kind": &"melee",
		"can_be_parried": true,
		"source": self,
	})


func _get_default_stun_duration(hit_data: Dictionary) -> float:
	match StringName(hit_data.get("attack_kind", &"light_attack")):
		&"attack_heavy":
			return 0.24
		&"shoot":
			return 0.14
		_:
			return 0.16


func _get_default_knockback(hit_data: Dictionary) -> Vector2:
	var source_position := hit_data.get("source_position", global_position) as Vector2
	var horizontal_direction := signf(global_position.x - source_position.x)
	if is_zero_approx(horizontal_direction):
		horizontal_direction = -float(signi(signals.facing_direction))
	match StringName(hit_data.get("attack_kind", &"light_attack")):
		&"attack_heavy":
			return Vector2(horizontal_direction * 120.0, -28.0)
		&"shoot":
			return Vector2(horizontal_direction * 80.0, -20.0)
		_:
			return Vector2(horizontal_direction * 64.0, -14.0)


func _on_hurt_requested(_hit_data: Variant, _damage_result: DamageResult) -> void:
	_body_visual.color = Color(1, 0.8, 0.4, 1)
	if _status_text_remaining <= 0.0:
		_show_status_text("HIT")


func _on_death_requested(_damage_result: DamageResult) -> void:
	signals.is_dead = true
	signals.can_accept_input = false
	_respawn_remaining = respawn_delay
	_attack_active_remaining = 0.0
	_attack_area.monitoring = false
	_knockback_velocity = Vector2.ZERO
	_body_visual.color = Color(0.18, 0.18, 0.18, 1)
	_show_status_text("DOWN")


func _apply_gravity(delta: float) -> void:
	if hover_in_place:
		_vertical_velocity = 0.0
		return
	if global_position.y < floor_y or _vertical_velocity < 0.0 or _knockback_velocity.y < 0.0:
		_vertical_velocity += gravity * delta
		return
	_vertical_velocity = 0.0


func _show_status_text(text: String) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_text_remaining = 0.75


func _update_status_label() -> void:
	if _status_label == null:
		return
	_status_label.visible = _status_text_remaining > 0.0 and not signals.is_dead
	if not _status_label.visible:
		return
	var height_bonus := clampf((floor_y - global_position.y) * 0.12, 0.0, 26.0)
	_status_label.position = Vector2(-46.0, -72.0 - height_bonus)
