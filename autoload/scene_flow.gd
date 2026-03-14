extends Node


signal transition_started(target_path: String)
signal transition_finished(target_path: String)


func change_scene(target_path: String) -> void:
	if target_path.is_empty():
		push_warning("SceneFlow received an empty target path.")
		return
	transition_started.emit(target_path)
	var error_code: Error = get_tree().change_scene_to_file(target_path)
	if error_code != OK:
		push_error("SceneFlow failed to change scene to: %s" % target_path)
		return
	transition_finished.emit(target_path)


func reload_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		push_warning("SceneFlow could not reload because there is no current scene.")
		return
	change_scene(current_scene.scene_file_path)
