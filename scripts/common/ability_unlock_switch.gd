class_name AbilityUnlockSwitch
extends Area2D


@export_enum("double_jump", "swim", "grapple") var ability_name: String = "double_jump"
@export var target_path: NodePath

@onready var _label: Label = $Label
@onready var _visual: Polygon2D = $Visual


func _ready() -> void:
	monitoring = true
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_update_display()


func _on_body_entered(body: Node) -> void:
	if not body is PlayerTestActor:
		return
	var actor := body as PlayerTestActor
	actor.toggle_ability_unlock(StringName(ability_name))
	_update_display()


func _update_display() -> void:
	var actor := get_node_or_null(target_path) as PlayerTestActor
	var is_unlocked := false
	if actor != null:
		is_unlocked = actor.is_ability_unlocked(StringName(ability_name))
	if _label != null:
		_label.text = "%s: %s" % [_get_title(), "ON" if is_unlocked else "OFF"]
	if _visual != null:
		_visual.color = Color(0.286275, 0.72549, 0.431373, 1.0) if is_unlocked else Color(0.756863, 0.305882, 0.305882, 1.0)


func _get_title() -> String:
	match ability_name:
		"double_jump":
			return "Double Jump"
		"swim":
			return "Swim"
		"grapple":
			return "Grapple"
		_:
			return String(ability_name)
