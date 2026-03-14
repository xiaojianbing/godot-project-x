extends Node


var _resource_cache: Dictionary = {}


func load_resource(path: String) -> Resource:
	if path.is_empty():
		push_warning("ConfigService received an empty resource path.")
		return null
	if _resource_cache.has(path):
		return _resource_cache[path]
	var resource: Resource = load(path)
	if resource == null:
		push_warning("ConfigService could not load resource: %s" % path)
		return null
	_resource_cache[path] = resource
	return resource


func get_cached_resource(path: String) -> Resource:
	return _resource_cache.get(path)


func clear_cache() -> void:
	_resource_cache.clear()
