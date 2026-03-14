class_name CharacterMotionProfile
extends Resource


@export var base_move_speed: float = 240.0
@export var ground_acceleration: float = 1600.0
@export var ground_deceleration: float = 1800.0
@export var crouch_move_speed: float = 120.0
@export var crouch_dash_speed: float = 360.0
@export var crouch_dash_duration: float = 0.16
@export var standing_collision_height: float = 30.0
@export var crouch_collision_height: float = 18.0
@export var jump_velocity: float = -430.0
@export var double_jump_velocity: float = -390.0
@export var max_air_jumps: int = 1
@export var gravity_up: float = 1200.0
@export var gravity_down: float = 1600.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12
@export var free_fall_reference_speed: float = 180.0
@export var wall_slide_speed_ratio: float = 0.5
@export var wall_jump_horizontal_speed: float = 260.0
@export var wall_jump_vertical_speed: float = -400.0
@export var wall_jump_input_lock_time: float = 0.12
@export var dash_speed: float = 420.0
@export var dash_duration: float = 0.14
@export var dash_cooldown: float = 0.18
@export var swim_horizontal_speed: float = 140.0
@export var swim_vertical_speed: float = 130.0
@export var swim_acceleration: float = 900.0
@export var swim_deceleration: float = 1000.0
@export var swim_buoyancy: float = 36.0
@export var swim_surface_exit_boost: float = 120.0
@export var grapple_search_radius: float = 220.0
@export var grapple_snap_angle: float = 80.0
@export var grapple_initial_speed_ratio: float = 0.45
@export var grapple_pull_speed: float = 860.0
@export var grapple_min_pull_duration: float = 0.12
@export var grapple_arrive_threshold: float = 18.0
@export var grapple_release_boost: float = 180.0
@export var grapple_release_duration: float = 0.08
@export var grapple_release_deceleration: float = 2200.0
@export var corner_correction_distance: float = 8.0
@export var ledge_climb_duration: float = 0.34
@export var dash_cost_multiplier: float = 1.0
@export var air_control_multiplier: float = 1.0
@export var special_terrain_speed_multiplier: float = 0.55
