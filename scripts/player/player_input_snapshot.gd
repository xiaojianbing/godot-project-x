class_name PlayerInputSnapshot
extends RefCounted


var move_axis: float = 0.0
var move_up_pressed: bool = false
var move_up_just_pressed: bool = false
var move_down_pressed: bool = false
var jump_pressed: bool = false
var jump_just_pressed: bool = false
var dash_just_pressed: bool = false
var grapple_just_pressed: bool = false


func update_from_input() -> void:
	move_axis = Input.get_axis("move_left", "move_right")
	move_up_pressed = Input.is_action_pressed("move_up")
	move_up_just_pressed = Input.is_action_just_pressed("move_up")
	move_down_pressed = Input.is_action_pressed("move_down")
	jump_pressed = Input.is_action_pressed("jump")
	jump_just_pressed = Input.is_action_just_pressed("jump")
	dash_just_pressed = Input.is_action_just_pressed("dash")
	grapple_just_pressed = Input.is_action_just_pressed("grapple")
