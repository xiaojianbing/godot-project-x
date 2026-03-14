class_name CombatFoundationTestRoom
extends Node2D


const RESET_ACTION := &"combat_reset"


@onready var _player: Node2D = $Player
@onready var _melee_dummy: EnemyCharacter = $MeleeDummy
@onready var _projectile_dummy: EnemyCharacter = $ProjectileDummy

var _player_spawn: Vector2 = Vector2.ZERO
var _melee_dummy_spawn: Vector2 = Vector2.ZERO
var _projectile_dummy_spawn: Vector2 = Vector2.ZERO


func _ready() -> void:
	_ensure_reset_input_action()
	_player_spawn = _player.global_position
	_melee_dummy_spawn = _melee_dummy.global_position
	_projectile_dummy_spawn = _projectile_dummy.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(RESET_ACTION):
		reset_room()


func reset_room() -> void:
	if _player != null:
		_player.global_position = _player_spawn
	if _player is PlayerTestActor:
		var actor := _player as PlayerTestActor
		actor.reset_for_testroom(_player_spawn)
	if _melee_dummy != null:
		_melee_dummy.respawn_at(_melee_dummy_spawn)
	if _projectile_dummy != null:
		_projectile_dummy.respawn_at(_projectile_dummy_spawn)
	for child in get_children():
		if child is ParryProjectile:
			child.queue_free()


func _ensure_reset_input_action() -> void:
	if not InputMap.has_action(RESET_ACTION):
		InputMap.add_action(RESET_ACTION)
	_add_key_if_missing(KEY_T)
	_add_joy_button_if_missing(JOY_BUTTON_BACK)


func _add_key_if_missing(keycode: Key) -> void:
	for input_event in InputMap.action_get_events(RESET_ACTION):
		if input_event is InputEventKey and input_event.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(RESET_ACTION, event)


func _add_joy_button_if_missing(button_index: JoyButton) -> void:
	for input_event in InputMap.action_get_events(RESET_ACTION):
		if input_event is InputEventJoypadButton and input_event.button_index == button_index:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(RESET_ACTION, event)
