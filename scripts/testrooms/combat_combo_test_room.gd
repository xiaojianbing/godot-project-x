class_name CombatComboTestRoom
extends Node2D


const RESET_ACTION := &"combat_reset"


@onready var _player: PlayerTestActor = $Player
@onready var _small_dummy: CombatDummy = $SmallDummy
@onready var _large_dummy: CombatDummy = $LargeDummy
@onready var _armor_dummy: CombatDummy = $ArmorDummy
@onready var _launcher_dummy: CombatDummy = $LauncherDummy
@onready var _air_dummy: CombatDummy = $AirDummy

var _player_spawn: Vector2 = Vector2.ZERO
var _small_dummy_spawn: Vector2 = Vector2.ZERO
var _large_dummy_spawn: Vector2 = Vector2.ZERO
var _armor_dummy_spawn: Vector2 = Vector2.ZERO
var _launcher_dummy_spawn: Vector2 = Vector2.ZERO
var _air_dummy_spawn: Vector2 = Vector2.ZERO


func _ready() -> void:
	_ensure_reset_input_action()
	if _player != null:
		_player_spawn = _player.global_position
	if _small_dummy != null:
		_small_dummy_spawn = _small_dummy.global_position
	if _large_dummy != null:
		_large_dummy_spawn = _large_dummy.global_position
	if _armor_dummy != null:
		_armor_dummy_spawn = _armor_dummy.global_position
	if _launcher_dummy != null:
		_launcher_dummy_spawn = _launcher_dummy.global_position
	if _air_dummy != null:
		_air_dummy_spawn = _air_dummy.global_position
	_configure_targets()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(RESET_ACTION):
		reset_room()


func reset_room() -> void:
	if _player != null:
		_player.global_position = _player_spawn
		_player.reset_for_testroom(_player_spawn)
	_reset_dummy(_small_dummy, _small_dummy_spawn)
	_reset_dummy(_large_dummy, _large_dummy_spawn)
	_reset_dummy(_armor_dummy, _armor_dummy_spawn)
	_reset_dummy(_launcher_dummy, _launcher_dummy_spawn)
	_reset_dummy(_air_dummy, _air_dummy_spawn)
	_clear_runtime_objects()
	_configure_targets()


func _reset_dummy(dummy: CombatDummy, spawn_position: Vector2) -> void:
	if dummy == null:
		return
	dummy.global_position = spawn_position
	dummy.respawn_at(spawn_position)


func _configure_targets() -> void:
	if _armor_dummy != null and _armor_dummy.signals != null:
		_armor_dummy.signals.has_super_armor = true
	if _small_dummy != null and _small_dummy.signals != null:
		_small_dummy.signals.has_super_armor = false
	if _large_dummy != null and _large_dummy.signals != null:
		_large_dummy.signals.has_super_armor = false
	if _launcher_dummy != null and _launcher_dummy.signals != null:
		_launcher_dummy.signals.has_super_armor = false
	if _air_dummy != null and _air_dummy.signals != null:
		_air_dummy.signals.has_super_armor = false


func _clear_runtime_objects() -> void:
	for node in get_tree().get_nodes_in_group("grapple_points"):
		if node != null and node.has_method("is_combat_chase_point") and bool(node.call("is_combat_chase_point")):
			node.queue_free()
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
