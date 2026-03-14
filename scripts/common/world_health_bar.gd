class_name WorldHealthBar
extends Node2D


@export var target_path: NodePath
@export var bar_size: Vector2 = Vector2(40.0, 6.0)
@export var bar_offset: Vector2 = Vector2(-20.0, -30.0)
@export var background_color: Color = Color(0.12, 0.12, 0.14, 0.9)
@export var fill_color: Color = Color(0.91, 0.26, 0.3, 0.95)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.9)


func _process(_delta: float) -> void:
	visible = _get_target_stats() != null
	if visible:
		queue_redraw()


func _draw() -> void:
	var stats: CharacterStats = _get_target_stats()
	if stats == null:
		return
	var max_hp := maxf(stats.max_hp, 1.0)
	var hp_ratio := clampf(stats.current_hp / max_hp, 0.0, 1.0)
	var bar_rect := Rect2(bar_offset, bar_size)
	var fill_rect := Rect2(bar_offset, Vector2(bar_size.x * hp_ratio, bar_size.y))
	draw_rect(bar_rect, background_color, true)
	draw_rect(fill_rect, fill_color, true)
	draw_rect(bar_rect, border_color, false, 1.0)


func _get_target_stats() -> CharacterStats:
	var target := get_node_or_null(target_path)
	if target == null:
		return null
	return target.get("stats") as CharacterStats
