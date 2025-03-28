extends Node

var routes = preload('res://routes.tres')
var history: Array[Route] = []
var scene_stack: Array[Node] = []

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("dev_reload"):
		# remove current scene and reload the current route
		print("[Router] Reloading current route")
		if scene_stack.size() > 0:
			var last_scene = scene_stack.pop_back()
			last_scene.queue_free()
		if history.size() > 0:
			var current_route = history[history.size() - 1]
			var new_scene = current_route.scene.instantiate()
			scene_stack.append(new_scene)
			add_child(new_scene)

func navigate(route_name: String) -> bool:
	print("[Router] Attempting to navigate to route: ", route_name)
	var current_route
	if history.size() == 0:
		current_route = _find_root_route(routes)
		scene_stack.append(get_tree().root.get_child(get_child_count() - 1))
		print("[Router] Initialized current_route to root route")
	else:
		current_route = history[history.size() - 1]
	print("[Router] Current route: ", current_route.name)
	
	var next_route: Route
	if route_name.begins_with("/"):
		# For absolute paths, search from root
		var clean_name = route_name.substr(1)  # Remove leading slash
		next_route = _find_route_by_name(clean_name, routes.subroutes)
	else:
		# For relative paths, search in current route's subroutes
		next_route = _find_route_by_name(route_name, current_route.subroutes)
	
	if not next_route:
		print("[Router] Failed to find route: ", route_name)
		return false
	
	_handle_navigate(next_route)
	return true

func go_back() -> bool:
	print("[Router] Attempting to go back")
	if history.size() < 2:
		print("[Router] Cannot go back: not enough history")
		return false
	
	_handle_back()
	return true

func go_root() -> bool:
	print("[Router] Attempting to go to root")
	var root_route = _find_root_route(routes)
	if not root_route:
		print("[Router] Failed to find root route")
		return false
	
	_clear_history_scenes()
	get_tree().root.add_child(root_route.scene.instantiate())
	return true

func _find_root_route(route: Route) -> Route:
	if route.is_root:
		return route
	for subroute in route.subroutes:
		var found = _find_root_route(subroute)
		if found:
			return found
	return null

func _find_route_by_name(name: String, routes_to_search: Array[Route]) -> Route:
	for route in routes_to_search:
		if route.name == name:
			return route
	return null

func _handle_navigate(route: Route) -> void:
	var new_scene = route.scene.instantiate()
	print("[Router] Navigating to route: ", route.name)
	if route.is_root:
		print("[Router] Route is root, clearing history")
		_clear_history_scenes()
	add_child(new_scene)
	scene_stack.append(new_scene)
	history.append(route)
	print("[Router] History stack: ", history.map(func(r): return r.name))

func _handle_back() -> void:
	print("[Router] Going back")
	history.pop_back()
	var popped_scene = scene_stack.pop_back()
	if popped_scene and popped_scene.is_inside_tree():
		popped_scene.queue_free()

func _clear_history_scenes() -> void:
	for scene in scene_stack:
		scene.queue_free()
	scene_stack.clear()
	history.clear()
	print("[Router] Cleared history and scene stack")
