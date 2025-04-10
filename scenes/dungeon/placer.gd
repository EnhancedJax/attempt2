class_name DungeonRoomPlacer

var tile_size : int
var gap_size : int
var room_parent : Node2D
var room_scenes : Array[RoomBase] = []
var _room_positions : Dictionary[int, Vector2] = {}
var _rooms : Array[Dungen.Room] = []
var _shuffled_room_lists: Dictionary = {}
var _current_indices: Dictionary = {}
var _used_special_rooms: Array[PackedScene] = []

func _init(_room_parent: Node2D, _tile_size: int, _gap_size: int) -> void:
	room_parent = _room_parent
	tile_size = _tile_size
	gap_size = _gap_size * tile_size

func place_rooms(rooms : Array[Dungen.Room]) -> Array[RoomBase]:
	_rooms = rooms
	_pick_room_scenes()
	_calculate_positions()
	_spawn_rooms()
	return room_scenes

func _pick_room_scenes() -> void:
	_used_special_rooms.clear()
	for i in range(_rooms.size()):
		var room_type: Dungen.RoomType = _rooms[i].room_type
		
		# For enemy rooms, check if we can use a special room based on TLBR
		if room_type == Dungen.RoomType.ENEMY:
			var tlbr_string = _get_tlbr_string(_rooms[i])
			var special_room = _try_get_special_room(tlbr_string)
			
			if special_room:
				room_scenes.append(special_room.instantiate())
				continue
		
		# Initialize shuffled list if needed
		if not _shuffled_room_lists.has(room_type):
			var room_scenes_list = Lookup.get_room_list(room_type)
			_shuffled_room_lists[room_type] = room_scenes_list.duplicate()
			_shuffled_room_lists[room_type].shuffle()
			_current_indices[room_type] = 0
		
		# Reset and reshuffle if we've used all scenes
		if _current_indices[room_type] >= _shuffled_room_lists[room_type].size():
			_shuffled_room_lists[room_type].shuffle()
			_current_indices[room_type] = 0
		
		# Get next scene from shuffled list
		var picked_scene = _shuffled_room_lists[room_type][_current_indices[room_type]]
		_current_indices[room_type] += 1
		room_scenes.append(picked_scene.instantiate())

func _calculate_positions() -> void:
	# Create a dictionary to map room id -> computed world position (as Vector2).
	# In these positions, the room scene’s top-left corner is considered the origin.
	# Place the beginning room (room id 0) arbitrarily at (0,0).
	_room_positions[0] = Vector2(0, 0)
	
	# Use a queue to propagate positions from room to room based on the door constraints.
	var queue = [0]
	while queue.size() > 0:
		var current_idx = queue.pop_front()
		var current_scene = room_scenes[current_idx]
		var current_pos = _room_positions[current_idx]
		var neighbours = _rooms[current_idx].neighbours

		if neighbours.left != -1 and not _room_positions.has(neighbours.left):
			var left_scene = room_scenes[neighbours.left]
			var left_pos = _compute_neighbor_position(current_pos, current_scene, left_scene, Dungen.Direction.LEFT)
			_room_positions[neighbours.left] = left_pos
			queue.append(neighbours.left)
		if neighbours.right != -1 and not _room_positions.has(neighbours.right):
			var right_scene = room_scenes[neighbours.right]
			var right_pos = _compute_neighbor_position(current_pos, current_scene, right_scene, Dungen.Direction.RIGHT)
			_room_positions[neighbours.right] = right_pos
			queue.append(neighbours.right)
		if neighbours.top != -1 and not _room_positions.has(neighbours.top):
			var top_scene = room_scenes[neighbours.top]
			var top_pos = _compute_neighbor_position(current_pos, current_scene, top_scene, Dungen.Direction.TOP)
			_room_positions[neighbours.top] = top_pos
			queue.append(neighbours.top)
		if neighbours.bottom != -1 and not _room_positions.has(neighbours.bottom):
			var bottom_scene = room_scenes[neighbours.bottom]
			var bottom_pos = _compute_neighbor_position(current_pos, current_scene, bottom_scene, Dungen.Direction.BOTTOM)
			_room_positions[neighbours.bottom] = bottom_pos
			queue.append(neighbours.bottom)

func _spawn_rooms() -> void:
	# Now that all room positions are computed, place the instanced room scenes.
	# The computed position represents the room's top-left corner in world space (in pixels).
	for i in range(_rooms.size()):
		var scene_instance = room_scenes[i]
		scene_instance.room_data = _rooms[i]
		
		# Configure door settings based on connections from the matrix.
		var door_config: Array[bool] = [false, false, false, false]  # [top, left, bottom, right]
		var room = _rooms[i]
		if room.neighbours.top != -1:
			door_config[0] = true
		if room.neighbours.left != -1:
			door_config[1] = true
		if room.neighbours.bottom != -1:
			door_config[2] = true
		if room.neighbours.right != -1:
			door_config[3] = true
		
		# Apply door configuration (for door placement/dimension data) and open all doors.
		scene_instance.door_config = door_config

		# Compute world position relative to the parent Node2D.
		var world_position = _room_positions[i]
		scene_instance.position = world_position

		# Disable and hide all rooms by default
		scene_instance.disable()
		
		# Defer adding the scene instance as a child so that it gets properly added.
		room_parent.call_deferred("add_child", scene_instance)
	
# Calculate room origin position for neighbor junction.
# current_pos: current room's world origin (top-left corner) as Vector2.
# current_scene: current room's chosen scene (with door properties)
# neighbor_scene: neighbor room's chosen scene.
# dir_code: the door direction used on current room.
# 
# This function computes the neighbor room’s position so that the two rooms’ doors are aligned,
# and then adds a GAP (in the connection direction) so that the rooms are spaced apart.
func _get_tlbr_string(room: Dungen.Room) -> String:
	# Convert the room's neighbor connections to a TLBR string (1 for connection, 0 for no connection)
	var tlbr = ""
	tlbr += "1" if room.neighbours.top != -1 else "0"
	tlbr += "1" if room.neighbours.left != -1 else "0"
	tlbr += "1" if room.neighbours.bottom != -1 else "0"
	tlbr += "1" if room.neighbours.right != -1 else "0"
	return tlbr

func _try_get_special_room(tlbr_string: String) -> PackedScene:
	# Get all special enemy rooms
	var special_rooms = Lookup.get_special_enemy_room_list()
	
	# Filter rooms that match the TLBR pattern and haven't been used yet
	var matching_rooms: Array[Lookup.SpecialEnemyRoom] = []
	for special_room in special_rooms:
		if special_room.tlbr == tlbr_string and not _used_special_rooms.has(special_room.scene):
			matching_rooms.append(special_room)
	
	# If we have matching rooms, pick one randomly and mark it as used
	if matching_rooms.size() > 0:
		var random_index = randi() % matching_rooms.size()
		var selected_room = matching_rooms[random_index]
		_used_special_rooms.append(selected_room.scene)
		return selected_room.scene
	
	return null

func _compute_neighbor_position(current_pos: Vector2, current_scene: Node, neighbor_scene: Node, dir_code: int) -> Vector2:
	# Obtain the door positions (in tile coordinates) for current room and the neighbor.
	var door_current: Vector2 = Dungen.get_door_value(current_scene, dir_code)
	var door_neighbor: Vector2 = Dungen.get_door_value(neighbor_scene, Dungen.opposite_direction[dir_code])
	
	# Compute the direction vector associated with the door connection.
	# Even though our get_door_value returns positions in tile units, we use the direction
	# from the passed code to add a GAP in the proper direction (normalized).
	var vec: Vector2
	match dir_code:
		Dungen.Direction.TOP:
			vec = Vector2(0, -1)
		Dungen.Direction.LEFT:
			vec = Vector2(-1, 0)
		Dungen.Direction.BOTTOM:
			vec = Vector2(0, 1)
		Dungen.Direction.RIGHT:
			vec = Vector2(1, 0)
		_:
			vec = Vector2.ZERO
	
	# The basic alignment (without gap) is computed as:
	# neighbor_pos = current_pos + (door_current - door_neighbor)*TILE_SIZE
	# Now we add GAP displacement in the connection direction.
	return current_pos + (door_current - door_neighbor) * tile_size + gap_size * vec
