class_name DungeonRoomPlacer

var tile_size : int
var gap_size : int
var room_parent : Node2D
var room_scenes : Array[RoomBase] = []
var _room_positions : Dictionary[int, Vector2] = {}
var _rooms : Array[Dungen.Room] = []

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
	for i in range(_rooms.size()):
		# Get the room's type from its 'nodes' dictionary.
		var room_type: Dungen.RoomType = _rooms[i].room_type
		var room_scenes_list = Lookup.get_room_list(room_type)
		# Instantiate the scene based on the room's type.
		var picked_scene = room_scenes_list[randi() % room_scenes_list.size()]
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
			var left_pos = _compute_neighbor_position(current_pos, current_scene, left_scene, Dungen.DIR_LEFT)
			_room_positions[neighbours.left] = left_pos
			queue.append(neighbours.left)
		if neighbours.right != -1 and not _room_positions.has(neighbours.right):
			var right_scene = room_scenes[neighbours.right]
			var right_pos = _compute_neighbor_position(current_pos, current_scene, right_scene, Dungen.DIR_RIGHT)
			_room_positions[neighbours.right] = right_pos
			queue.append(neighbours.right)
		if neighbours.top != -1 and not _room_positions.has(neighbours.top):
			var top_scene = room_scenes[neighbours.top]
			var top_pos = _compute_neighbor_position(current_pos, current_scene, top_scene, Dungen.DIR_TOP)
			_room_positions[neighbours.top] = top_pos
			queue.append(neighbours.top)
		if neighbours.bottom != -1 and not _room_positions.has(neighbours.bottom):
			var bottom_scene = room_scenes[neighbours.bottom]
			var bottom_pos = _compute_neighbor_position(current_pos, current_scene, bottom_scene, Dungen.DIR_BOTTOM)
			_room_positions[neighbours.bottom] = bottom_pos
			queue.append(neighbours.bottom)

		
		# # For every potential neighbor:
		# for neighbor_id in range(_rooms.size()):
		#     var code = matrix[current_id][neighbor_id]
		#     if code != 0:
		#         # We have a connection from current room at current_id to neighbor_id in direction "code".
		#         var neighbor_scene = room_scenes[neighbor_id]
		#         var computed_pos = _compute_neighbor_position(current_pos, current_scene, neighbor_scene, code)
		#         # If the neighbor hasn't been placed, set its position.
		#         if not room_positions.has(neighbor_id):
		#             room_positions[neighbor_id] = computed_pos
		#             queue.append(neighbor_id)
		#         else:
		#             # If already set, check for conflict and warn if misaligned.
		#             if room_positions[neighbor_id] != computed_pos:
		#                 push_warning("Conflict detected for room %d alignment. Expected %s but found %s" %
		#                     [neighbor_id, str(room_positions[neighbor_id]), str(computed_pos)])
		#                 # In a full implementation, you might resolve this conflict.

func _spawn_rooms() -> void:
	# Now that all room positions are computed, place the instanced room scenes.
	# The computed position represents the room's top-left corner in world space (in pixels).
	for i in range(_rooms.size()):
		var scene_instance = room_scenes[i]
		# var room_type = nodes[i].type
		
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
		# scene_instance.room_id = i

		# Compute world position relative to the parent Node2D.
		var world_position = _room_positions[i]
		scene_instance.position = world_position
		
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
func _compute_neighbor_position(current_pos: Vector2, current_scene: Node, neighbor_scene: Node, dir_code: int) -> Vector2:
	# Obtain the door positions (in tile coordinates) for current room and the neighbor.
	var door_current: Vector2 = Dungen.get_door_value(current_scene, dir_code)
	var door_neighbor: Vector2 = Dungen.get_door_value(neighbor_scene, Dungen.opposite_direction[dir_code])
	
	# Compute the direction vector associated with the door connection.
	# Even though our get_door_value returns positions in tile units, we use the direction
	# from the passed code to add a GAP in the proper direction (normalized).
	var vec: Vector2
	match dir_code:
		Dungen.DIR_TOP:
			vec = Vector2(0, -1)
		Dungen.DIR_LEFT:
			vec = Vector2(-1, 0)
		Dungen.DIR_BOTTOM:
			vec = Vector2(0, 1)
		Dungen.DIR_RIGHT:
			vec = Vector2(1, 0)
		_:
			vec = Vector2.ZERO
	
	# The basic alignment (without gap) is computed as:
	# neighbor_pos = current_pos + (door_current - door_neighbor)*TILE_SIZE
	# Now we add GAP displacement in the connection direction.
	return current_pos + (door_current - door_neighbor) * tile_size + gap_size * vec
