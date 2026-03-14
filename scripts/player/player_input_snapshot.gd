class_name PlayerInputSnapshot
extends RefCounted


var move_axis: float = 0.0
var move_vector: Vector2 = Vector2.ZERO
var move_up_pressed: bool = false
var move_up_just_pressed: bool = false
var move_down_pressed: bool = false
var jump_pressed: bool = false
var jump_just_pressed: bool = false
var dash_just_pressed: bool = false
var grapple_just_pressed: bool = false
var guard_pressed: bool = false
var guard_just_pressed: bool = false
var attack_light_just_pressed: bool = false
var attack_heavy_just_pressed: bool = false
var shoot_pressed: bool = false
var shoot_just_pressed: bool = false
var shoot_just_released: bool = false
var aim_vector: Vector2 = Vector2.ZERO


func update_from_input() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	move_vector = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	move_up_pressed = Input.is_action_pressed("move_up")
	move_up_just_pressed = Input.is_action_just_pressed("move_up")
	move_down_pressed = Input.is_action_pressed("move_down")
	jump_pressed = Input.is_action_pressed("jump")
	jump_just_pressed = Input.is_action_just_pressed("jump")
	dash_just_pressed = Input.is_action_just_pressed("dash")
	grapple_just_pressed = Input.is_action_just_pressed("grapple")
	guard_pressed = Input.is_action_pressed("guard")
	guard_just_pressed = Input.is_action_just_pressed("guard")
	attack_light_just_pressed = Input.is_action_just_pressed("attack_light")
	attack_heavy_just_pressed = Input.is_action_just_pressed("attack_heavy")
	shoot_pressed = Input.is_action_pressed("shoot")
	shoot_just_pressed = Input.is_action_just_pressed("shoot")
	shoot_just_released = Input.is_action_just_released("shoot")
	aim_vector = Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	var joypads := Input.get_connected_joypads()
	if joypads.size() > 0:
		var raw_move := Vector2(Input.get_joy_axis(joypads[0], JOY_AXIS_LEFT_X), Input.get_joy_axis(joypads[0], JOY_AXIS_LEFT_Y))
		if raw_move.length() >= 0.15:
			move_vector = raw_move
		var raw_aim := Vector2(Input.get_joy_axis(joypads[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(joypads[0], JOY_AXIS_RIGHT_Y))
		if raw_aim.length() >= 0.2:
			aim_vector = raw_aim
