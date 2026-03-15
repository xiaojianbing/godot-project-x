class_name ProjectileEmitterTrap
extends Node2D


@export var projectile_scene: PackedScene
@export var target_path: NodePath
@export var owner_team: StringName = &"enemy"
@export var damage: float = 10.0
@export var projectile_speed: float = 240.0
@export var fire_interval: float = 2.0
@export var initial_delay: float = 0.5
@export var burst_count: int = 1
@export var burst_spacing: float = 0.08
@export var projectile_lifetime: float = 2.8


var _fire_cooldown_remaining: float = 0.0
var _burst_shots_remaining: int = 0
var _burst_spacing_remaining: float = 0.0

@onready var _spawn_marker: Marker2D = $SpawnMarker


func _ready() -> void:
	reset_emitter()


func _physics_process(delta: float) -> void:
	if _burst_shots_remaining > 0:
		_burst_spacing_remaining = maxf(0.0, _burst_spacing_remaining - delta)
		if _burst_spacing_remaining <= 0.0:
			_fire_one_shot()
			_burst_shots_remaining -= 1
			_burst_spacing_remaining = burst_spacing if _burst_shots_remaining > 0 else 0.0
		return
	_fire_cooldown_remaining = maxf(0.0, _fire_cooldown_remaining - delta)
	if _fire_cooldown_remaining <= 0.0:
		_start_burst()


func reset_emitter() -> void:
	_fire_cooldown_remaining = initial_delay
	_burst_shots_remaining = 0
	_burst_spacing_remaining = 0.0


func _start_burst() -> void:
	_burst_shots_remaining = maxi(1, burst_count)
	_burst_spacing_remaining = 0.0
	_fire_cooldown_remaining = fire_interval


func _fire_one_shot() -> void:
	if projectile_scene == null or _spawn_marker == null:
		return
	var projectile := projectile_scene.instantiate() as ParryProjectile
	if projectile == null:
		return
	var parent_node := get_parent()
	if parent_node == null:
		return
	parent_node.add_child(projectile)
	projectile.global_position = _spawn_marker.global_position
	projectile.set_owner_team(owner_team)
	projectile.damage = damage
	projectile.max_lifetime = projectile_lifetime
	var target := get_node_or_null(target_path) as Node2D
	var direction := Vector2.LEFT
	if target != null:
		# 这里直接锁定玩家当前位置发射，保证双发/空中弹反机关的测试路径稳定可复现。
		direction = (target.global_position - _spawn_marker.global_position).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.LEFT
	projectile.velocity = direction * projectile_speed
