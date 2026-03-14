class_name ParryProjectile
extends Area2D


@export var damage: float = 12.0
@export var owner_team: StringName = &"enemy"
@export var hitstun_duration: float = 0.14
@export var knockback: Vector2 = Vector2(80.0, -20.0)
@export var max_lifetime: float = 2.2
var velocity: Vector2 = Vector2.ZERO
var _has_resolved_hit: bool = false

@onready var _visual: Polygon2D = $Visual

var _lifetime_remaining: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_lifetime_remaining = max_lifetime
	_update_visual_style()


func _physics_process(delta: float) -> void:
	if _has_resolved_hit:
		return
	_lifetime_remaining = maxf(0.0, _lifetime_remaining - delta)
	if _lifetime_remaining <= 0.0:
		_resolve_hit()
		return
	global_position += velocity * delta
	_update_visual_orientation()


func reflect(reflect_direction: Vector2, speed_scale: float) -> void:
	set_owner_team(&"player")
	velocity = reflect_direction.normalized() * velocity.length() * speed_scale
	_has_resolved_hit = false
	_lifetime_remaining = max_lifetime


func set_owner_team(team: StringName) -> void:
	owner_team = team
	_update_visual_style()


func _on_body_entered(body: Node) -> void:
	if _has_resolved_hit:
		return
	if _should_ignore_body_collision(body):
		return
	if _should_resolve_on_body(body):
		_resolve_hit()


func _on_area_entered(area: Area2D) -> void:
	if _has_resolved_hit or area == null:
		return
	if area.name != "Hurtbox":
		return
	var target := area.get_parent()
	if target == null:
		return
	# 统一把飞行物命中结算收口到 projectile 自身，避免运行时实例因 owner 为空而漏掉 Hurtbox 命中。
	if owner_team == &"player" and target.has_method("receive_player_attack"):
		target.receive_player_attack({
			"damage": damage,
			"attack_kind": &"shoot",
			"source": self,
			"source_position": global_position,
			"stun_duration": hitstun_duration,
			"knockback": Vector2(signf(velocity.x) * absf(knockback.x), knockback.y),
		})
		_resolve_hit()
		return
	if owner_team == &"enemy" and target is EnemyCharacter:
		return
	if owner_team == &"enemy" and target is PlayerTestActor:
		var actor: PlayerTestActor = target as PlayerTestActor
		if actor.is_dashing() or actor.is_crouch_dashing():
			return
		var result := actor.receive_combat_hit({
			"damage": damage,
			"attack_kind": &"projectile",
			"can_be_parried": true,
			"is_projectile": true,
			"source": self,
			"source_position": global_position,
		})
		if owner_team == &"player" or result.was_blocked_by_invincible:
			return
		_resolve_hit()


func _should_ignore_body_collision(body: Node) -> bool:
	if owner_team == &"enemy" and (body is EnemyCharacter or body is PlayerTestActor):
		return true
	if owner_team == &"player" and (body is PlayerTestActor or body is EnemyCharacter):
		return true
	return false


func _should_resolve_on_body(body: Node) -> bool:
	if body is StaticBody2D or body is TileMapLayer:
		return true
	return false


func _resolve_hit() -> void:
	if _has_resolved_hit:
		return
	_has_resolved_hit = true
	queue_free()


func _update_visual_orientation() -> void:
	if _visual == null:
		return
	if velocity.length_squared() <= 0.001:
		return
	rotation = velocity.angle()


func _update_visual_style() -> void:
	if _visual == null:
		return
	if owner_team == &"player":
		_visual.color = Color(0.38, 0.92, 1.0, 1.0)
		return
	_visual.color = Color(1.0, 0.56, 0.24, 1.0)
