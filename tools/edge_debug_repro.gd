extends SceneTree


func _initialize() -> void:
	var player_scene := load("res://scenes/player/player_test_actor.tscn") as PackedScene
	var actor := player_scene.instantiate() as PlayerTestActor
	root.add_child(actor)
	if not InputMap.has_action("move_up"):
		actor._ensure_input_actions()
	await process_frame
	await process_frame

	var jump_keys := _collect_keycodes("jump")
	var move_up_keys := _collect_keycodes("move_up")
	print("[EDGE_REPRO] jump_keys=%s" % str(jump_keys))
	print("[EDGE_REPRO] move_up_keys=%s" % str(move_up_keys))
	print("[EDGE_REPRO] overlap_keys=%s" % str(_get_overlap(jump_keys, move_up_keys)))

	actor.signals.facing_direction = 1
	actor._ledge_top_point = Vector2(100.0, 100.0)
	actor.global_position = actor._get_ledge_hang_position()
	actor._is_edge_hanging = true
	print("[EDGE_REPRO] computed_hang_pos=%s head_y=%.1f platform_y=%.1f" % [str(actor.global_position), actor.global_position.y - actor.motion_profile.standing_collision_height * 0.5, actor._ledge_top_point.y])

	actor.controller.input_snapshot.move_up_pressed = true
	actor._update_edge_idle()
	print("[EDGE_REPRO] after_up_pressed edge_hanging=%s edge_climbing=%s climb_remaining=%.2f" % [str(actor.is_edge_hanging()), str(actor.is_edge_climbing()), actor._ledge_climb_remaining])

	quit()


func _collect_keycodes(action_name: StringName) -> Array[int]:
	var result: Array[int] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			result.append((event as InputEventKey).physical_keycode)
	return result


func _get_overlap(left: Array[int], right: Array[int]) -> Array[int]:
	var overlap: Array[int] = []
	for value in left:
		if value in right:
			overlap.append(value)
	return overlap
