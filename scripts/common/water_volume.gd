class_name WaterVolume
extends Area2D


@export_enum("shallow", "deep") var water_mode: String = "deep"
@export var requires_swim_unlock: bool = false
@export var respawn_marker_path: NodePath


func _ready() -> void:
	monitoring = true
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body is PlayerTestActor:
		return
	var actor := body as PlayerTestActor
	actor.on_water_volume_entered(StringName(water_mode), requires_swim_unlock, _get_respawn_position())


func _on_body_exited(body: Node) -> void:
	if not body is PlayerTestActor:
		return
	var actor := body as PlayerTestActor
	actor.on_water_volume_exited(StringName(water_mode))


func _get_respawn_position() -> Vector2:
	if respawn_marker_path == NodePath():
		return Vector2.ZERO
	var marker := get_node_or_null(respawn_marker_path)
	if marker is Node2D:
		return (marker as Node2D).global_position
	return Vector2.ZERO
