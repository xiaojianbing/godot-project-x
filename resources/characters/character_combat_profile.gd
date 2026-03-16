class_name CharacterCombatProfile
extends Resource


@export var hurt_invincible_duration: float = 0.24
@export var hurt_knockback_ground: Vector2 = Vector2(78.0, -54.0)
@export var hurt_knockback_projectile: Vector2 = Vector2(92.0, -68.0)
@export var guard_chip_ratio: float = 0.2
@export var guard_front_angle: float = 120.0
@export var light_attack_damage_scale: float = 1.0
@export var heavy_attack_damage_scale: float = 1.7
@export var shoot_damage_scale: float = 0.85
@export var light_attack_active_duration: float = 0.12
@export var light_attack_recovery_duration: float = 0.24
@export var heavy_attack_active_duration: float = 0.18
@export var heavy_attack_recovery_duration: float = 0.34
@export var shoot_release_recovery_duration: float = 0.26
@export var light_attack_hitstun_duration: float = 0.16
@export var heavy_attack_hitstun_duration: float = 0.24
@export var shoot_hitstun_duration: float = 0.14
@export var light_attack_hitbox_size: Vector2 = Vector2(22.0, 18.0)
@export var heavy_attack_hitbox_size: Vector2 = Vector2(28.0, 20.0)
@export var light_attack_hitbox_offset: Vector2 = Vector2(14.0, -4.0)
@export var heavy_attack_hitbox_offset: Vector2 = Vector2(18.0, -4.0)
@export var light_attack_knockback: Vector2 = Vector2(64.0, -14.0)
@export var heavy_attack_knockback: Vector2 = Vector2(120.0, -28.0)
@export var shoot_knockback: Vector2 = Vector2(80.0, -20.0)
@export var shoot_projectile_speed: float = 320.0
@export var shoot_projectile_lifetime: float = 2.2
@export var enemy_melee_windup_duration: float = 0.12
@export var enemy_melee_active_duration: float = 0.14
@export var enemy_melee_cooldown_duration: float = 1.35
@export var enemy_projectile_windup_duration: float = 0.1
@export var enemy_projectile_cooldown_duration: float = 2.4
@export var enemy_projectile_spawn_offset: Vector2 = Vector2(18.0, -10.0)
@export var parry_window_ground: float = 0.1
@export var parry_window_air: float = 0.08
@export var parry_invincible_duration: float = 0.22
@export var parry_enemy_stun_duration: float = 0.8
@export var air_parry_bounce_velocity: float = 320.0
@export var projectile_parry_speed_scale: float = 1.15
