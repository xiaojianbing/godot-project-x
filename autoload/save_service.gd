extends Node


const SAVE_ROOT := "user://saves"


func save_slot(slot_id: int, data: SaveSlotData) -> bool:
	if data == null:
		push_warning("SaveService tried to save null slot data.")
		return false
	DirAccess.make_dir_recursive_absolute(SAVE_ROOT)
	var save_path := _get_slot_path(slot_id)
	var error_code: Error = ResourceSaver.save(data, save_path)
	if error_code != OK:
		push_error("SaveService failed to save slot: %s" % str(slot_id))
		return false
	return true


func load_slot(slot_id: int) -> SaveSlotData:
	var save_path := _get_slot_path(slot_id)
	if not ResourceLoader.exists(save_path):
		return null
	var data: Resource = load(save_path)
	if data is SaveSlotData:
		return data as SaveSlotData
	push_warning("SaveService loaded an unexpected resource type for slot: %s" % str(slot_id))
	return null


func _get_slot_path(slot_id: int) -> String:
	return "%s/slot_%d.tres" % [SAVE_ROOT, slot_id]
