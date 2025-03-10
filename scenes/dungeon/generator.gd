extends Node2D

# Room type constants
enum RoomType { B, E, L, S, F }

# Direction codes (from the current room perspective)
const DIR_TOP = 1   # neighbor is at (0,-1)
const DIR_LEFT = 2  # neighbor is at (-1,0)
const DIR_BOTTOM = 3# neighbor is at (0,1)
const DIR_RIGHT = 4 # neighbor is at (1,0)

# Opposite direction mapping (for the reverse connection)
var opposite_direction = {
	DIR_TOP: DIR_BOTTOM,
	DIR_LEFT: DIR_RIGHT,
	DIR_BOTTOM: DIR_TOP,
	DIR_RIGHT: DIR_LEFT,
}

# Direction vectors (and corresponding random label order)
var directions = [
	{"vec": Vector2(0,-1), "code": DIR_TOP},
	{"vec": Vector2(-1,0), "code": DIR_LEFT},
	{"vec": Vector2(0,1),  "code": DIR_BOTTOM},
	{"vec": Vector2(1,0),  "code": DIR_RIGHT}
]

# A room is represented by a dictionary with:
#  id: int
#  pos: Vector2 - grid position
#  neighbors: Array of dictionaries { "id": neighbor_id, "dir": edge_code }
#  type: RoomType (optional at first)
var nodes = []         # List of nodes; index is the room id.
var grid = {}          # Dictionary mapping "x,y" -> room id
var n = 5  # number of enemy rooms (E)
var m = 1  # number of loot rooms (L)

# Constant for corridor floor width.
const corridor_width = 2

# We'll also store the room scenes in a dictionary for corridor drawing.
var room_scenes = {}

@onready var corridor_tilemap : TileMapLayer = $FloorTileLayer
@onready var corridor_wall_tilemap : TileMapLayer = $WallTileLayer
@onready var room_container : Node = $RoomNodes

func generate_new_dungeon() -> Dictionary:
	# Clear previously drawn corridors, if needed.
	corridor_tilemap.clear()
	corridor_wall_tilemap.clear()
	clear_rooms()
	var mat = generate()
	place_rooms(mat)
	draw_corridors()
	return {
		"nodes": nodes,
		"matrix": mat,
		"room_scenes": room_scenes
	}

func clear_rooms():
	# Remove all child nodes (room instances)
	for child in room_container.get_children():
		child.queue_free()

# Utility: convert a Vector2 position to a unique string key.
func pos_key(pos: Vector2) -> String:
	return str(pos.x) + "," + str(pos.y)

func generate():
	# Example parameters:
	# Total nodes = B + n E + m L + S + F = (n + m + 3)
	
	var total_rooms = n + m + 3
	# Try generation repeatedly until we get a valid non-linear dungeon.
	var max_attempts = 20
	var attempt = 0
	while attempt < max_attempts:
		if generate_dungeon(total_rooms):
			if assign_room_types(n, m):
				# if room types were assigned (and non-linear conditions met), break
				break
		attempt += 1
		reset_dungeon()
	
	if attempt >= max_attempts:
		print("Failed to generate a valid dungeon.")
		return
	
	var matrix = build_adjacency_matrix()
	print("Adjacency Matrix:")
	for row in matrix:
		print(row)
	print("")
	print("Dungeon Layout:")
	print_dungeon_layout()
	# Optionally, print node info:
	print("Node details:")
	for room in nodes:
		print("ID: %d, Pos: %s, Type: %s, Neighbors: %s" % [room.id, room.pos, room.type, room.neighbors])
	return matrix
	
	
# Reset the global dungeon data.
func reset_dungeon():
	nodes.clear()
	grid.clear()

# Generates the spanning tree on an infinite grid. Returns true if successful.
func generate_dungeon(total_rooms: int) -> bool:
	reset_dungeon()
	var next_id = 0
		
	# Place Beginning room B at (0,0)
	var b_room = {
		"id": next_id,
		"pos": Vector2(0,0),
		"neighbors": [],
		"type": RoomType.B
	}
	nodes.append(b_room)
	grid[pos_key(b_room.pos)] = next_id
	next_id += 1
	
	# B must have one edge only. Pick one random adjacent neighbor.
	var available_dirs = directions.duplicate()
	available_dirs.shuffle()
	var b_neighbor_pos
	var b_edge_code = 0
	for d in available_dirs:
		var candidate = b_room.pos + d.vec
		# No other room exists so candidate is free.
		b_neighbor_pos = candidate
		b_edge_code = d.code
		break
	# Create the neighbor. Its type will be forced to be E later.
	var neighbor = {
		"id": next_id,
		"pos": b_neighbor_pos,
		"neighbors": [],
		"type": null  # to be assigned
	}
	nodes.append(neighbor)
	grid[pos_key(b_neighbor_pos)] = next_id
	
	# Connect B <-> neighbor.
	add_connection(0, neighbor.id, b_edge_code)
	next_id += 1

	# Frontier: list of indices of nodes that can expand.
	# We do not allow B anymore since it must remain degree 1.
	var frontier = [ neighbor.id ]
	
	# Grow dungeon until total_rooms reached.
	while nodes.size() < total_rooms and frontier.size() > 0:
		# Pick a random node from frontier.
		frontier.shuffle()
		var current_id = frontier[0]
		var current_node = nodes[current_id]
		var placed = false
		
		# Try the directions in random order.
		var test_dirs = directions.duplicate()
		test_dirs.shuffle()
		for d in test_dirs:
			var candidate_pos = current_node.pos + d.vec
			var key = pos_key(candidate_pos)
			# Check if there is already a room here.
			if grid.has(key):
				continue
			# IMPORTANT: check that the candidate room will only touch the current node.
			# (We check all four cardinal neighbors of candidate_pos; if any room exists other than current_node, then skip.)
			var valid_candidate = true
			for adj in directions:
				var adj_pos = candidate_pos + adj.vec
				var adj_key = pos_key(adj_pos)
				if grid.has(adj_key):
					var adjacent_room_id = grid[adj_key]
					if adjacent_room_id != current_id:
						# If adjacent to B and B is not the current node, that would add an extra edge to B (or form a cycle)
						if nodes[adjacent_room_id].type == RoomType.B:
							valid_candidate = false
							break
						# Otherwise, touching another room means a potential cycle.
						valid_candidate = false
						break
			if not valid_candidate:
				continue
			# Valid candidate found. Create the new room.
			var new_room = {
				"id": next_id,
				"pos": candidate_pos,
				"neighbors": [],
				"type": null
			}
			nodes.append(new_room)
			grid[key] = next_id
			# Connect current node and new room.
			add_connection(current_id, next_id, d.code)
			next_id += 1
			placed = true
			# Add new room to frontier.
			frontier.append(new_room.id)
			# Also if the current node now has no more free directions, remove it from frontier.
			# (In our simple approach, we let the frontier remain and check later.)
			break
		if not placed:
			# If current frontier node cannot expand further, remove it from frontier.
			frontier.erase(current_id)
	# Check if we reached the total number of rooms:
	return nodes.size() == total_rooms

# Helper: Connect two nodes in our data structure, adding the direction code.
func add_connection(from_id: int, to_id: int, code: int) -> void:
	# Add connection in both directions.
	nodes[from_id].neighbors.append({"id": to_id, "dir": code})
	nodes[to_id].neighbors.append({"id": from_id, "dir": opposite_direction[code]})

# Assign the room types (E, L, S, F) according to the requested rules.
func assign_room_types(n: int, m: int) -> bool:
	# We already have B (id 0) and B's neighbor will remain E.
	# Total E should equal n. We already have B's neighbor forced to be E.
	# Next, choose F as the farthest room from B.
	var farthest = get_farthest_node(0)
	if farthest == null:
		# return false
		pass
	farthest.type = RoomType.F
	
	# S must be a leaf (degree1) that is not B (id 0) or F.
	var candidate_S = []
	for room in nodes:
		# A leaf has exactly one neighbor.
		if room.neighbors.size() == 1 and room.id != 0 and room.id != farthest.id:
			candidate_S.append(room)
		# Also ensure that S's only neighbor is an E eventually. At this point we haven’t assigned the neighbor types yet,
		# but in our spanning tree the neighbor of any leaf is its parent -- which we plan to assign as E or L later.
	if candidate_S.size() == 0:
		# If no candidate for S exists (i.e. dungeon is linear with only 2 leaves: B and F)
		# return false
		pass
	candidate_S.shuffle()
	var s_room = candidate_S[0]
	s_room.type = RoomType.S

	# Now assign the remaining nodes with types E or L.
	# Total remaining rooms (excluding B, S, F) should equal n-? + m.
	var remaining_nodes = []
	for room in nodes:
		if room.id == 0 or room.id == s_room.id or room.type == RoomType.F:
			continue
		if room.type != null:
			# B's neighbor is already forced to be E. (We assume that if a type is set, it must be E.)
			continue
		remaining_nodes.append(room)
	# Count how many E are already set aside (besides B)...
	var count_E = 0
	for room in nodes:
		if room.type == RoomType.E:
			count_E += 1
	# B's neighbor should already be E; if not set, then force it.
	# Determine how many E still need to be assigned.
	var remaining_E_needed = n - count_E
	# There are remaining_nodes.size() rooms that need to be assigned among E and L.
	if remaining_nodes.size() != (remaining_E_needed + m):
		# Inconsistent count -- generation failure.
		# return false
		pass
	remaining_nodes.shuffle()
	# First assign remaining_E_needed as E.
	for i in range(remaining_E_needed):
		remaining_nodes[i].type = RoomType.E
	# Then assign the rest as L.
	for i in range(remaining_E_needed, remaining_nodes.size()):
		remaining_nodes[i].type = RoomType.L

	# Also, for any room that is still not set but is adjacent to B's neighbor (should be E if reached from B) force to E.
	# (This is extra precaution.)
	for room in nodes:
		if room.type == null:
			room.type = RoomType.E
	# Check that B and F are leaves.
	if nodes[0].neighbors.size() != 1 or farthest.neighbors.size() != 1:
		# return false
		pass
	# Also, basic check: dungeon should not be linear, so there must be at least 3 leaves.
	var leaves = 0
	for room in nodes:
		if room.neighbors.size() == 1:
			leaves += 1
	if leaves < 3:
		# return false
		pass
	return true

# Returns the node (dictionary) that is farthest (largest number of steps) from the start_id using BFS.
func get_farthest_node(start_id: int) -> Dictionary:
	var dist = {}
	var visited = {}
	var q = []
	for room in nodes:
		dist[room.id] = -1
		visited[room.id] = false
	dist[start_id] = 0
	q.append(start_id)
	visited[start_id] = true
	while q.size() > 0:
		var current = q.pop_front()
		for edge in nodes[current].neighbors:
			var nb = edge.id
			if not visited[nb]:
				visited[nb] = true
				dist[nb] = dist[current] + 1
				q.append(nb)
			# If already visited, we keep the smaller distance.
	var max_d = -1
	var farthest_node = null
	for room in nodes:
		if dist[room.id] > max_d:
			max_d = dist[room.id]
			farthest_node = room
		# In case of tie, the first found.
	return farthest_node

# Build the adjacency (connection) matrix.
func build_adjacency_matrix():
	var total = nodes.size()
	# Create a 2D array (an array of arrays).
	var mat = []
	for i in range(total):
		mat.append([])
		for j in range(total):
			mat[i].append(0)
	# For each node, for each neighbor, set the corresponding edge code.
	for room in nodes:
		for edge in room.neighbors:
			# Compute direction from room.pos to neighbor.pos.
			var neighbor_room = nodes[edge.id]
			var delta = neighbor_room.pos - room.pos
			var code = 0
			if delta == Vector2(0,-1):
				code = DIR_TOP
			elif delta == Vector2(-1,0):
				code = DIR_LEFT
			elif delta == Vector2(0,1):
				code = DIR_BOTTOM
			elif delta == Vector2(1,0):
				code = DIR_RIGHT
			# Set the matrix entry.
			mat[room.id][edge.id] = code
		# (Since connections are symmetric, the neighbor entry was set when the connection was added.)
	return mat

# Print the dungeon layout by printing a grid with the room letter.
func print_dungeon_layout() -> void:
	# Determine grid bounds.
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for room in nodes:
		min_x = min(min_x, room.pos.x)
		max_x = max(max_x, room.pos.x)
		min_y = min(min_y, room.pos.y)
		max_y = max(max_y, room.pos.y)
	# Create a dictionary mapping positions to room letter.
	var layout = {}
	for room in nodes:
		var letter = ""
		match room.type:
			RoomType.B:
				letter = "B"
			RoomType.E:
				letter = "E"
			RoomType.L:
				letter = "L"
			RoomType.S:
				letter = "S"
			RoomType.F:
				letter = "F"
			_:
				letter = "?"
		layout[pos_key(room.pos)] = letter
	# Print grid row by row.
	for y in range(min_y, max_y+1):
		var line = ""
		for x in range(min_x, max_x+1):
			var key = pos_key(Vector2(x,y))
			if layout.has(key):
				line += layout[key]
			else:
				line += " "
		print(line)


#===============================================================================
# CONSTANTS AND ROOM SCENES
#===============================================================================
const TILE_SIZE := 16
const GAP      := 6  * TILE_SIZE  # minimum pixel gap between rooms

const ROOM_SCENES = {
	RoomType.B: [
		preload("res://scenes/rooms/level1/start.tscn"),
	],
	RoomType.E: [
		preload("res://scenes/rooms/level1/enemy1.tscn"),
		preload("res://scenes/rooms/level1/enemy2.tscn"),
	],
	RoomType.L: [
		preload("res://scenes/rooms/level1/loot.tscn"),
	],
	RoomType.S: [
		preload("res://scenes/rooms/level1/shop.tscn"),
	],
	RoomType.F: [
		preload("res://scenes/rooms/level1/end.tscn"),
	]
}


# Direction vectors for movement on the grid
func get_offset_from_code(code: int) -> Vector2:
	match code:
		DIR_TOP:
			return Vector2(0, -1)
		DIR_LEFT:
			return Vector2(-1, 0)
		DIR_BOTTOM:
			return Vector2(0, 1)
		DIR_RIGHT:
			return Vector2(1, 0)
		_:
			return Vector2.ZERO
#===============================================================================
# HELPER FUNCTIONS
#===============================================================================
# Returns the door Vector2 (in tile coordinates) from a room scene given the direction.
func get_door_value(scene_instance: Node, direction: int) -> Vector2:
	match direction:
		DIR_TOP:
			return scene_instance.entrances_top
		DIR_LEFT:
			return scene_instance.entrances_left
		DIR_BOTTOM:
			return scene_instance.entrances_bottom
		DIR_RIGHT:
			return scene_instance.entrances_right
		_:
			return Vector2.ZERO

# Calculate room origin position for neighbor junction.
# current_pos: current room's world origin (top-left corner) as Vector2.
# current_scene: current room's chosen scene (with door properties)
# neighbor_scene: neighbor room's chosen scene.
# dir_code: the door direction used on current room.
# 
# This function computes the neighbor room’s position so that the two rooms’ doors are aligned,
# and then adds a GAP (in the connection direction) so that the rooms are spaced apart.
func compute_neighbor_position(current_pos: Vector2, current_scene: Node, neighbor_scene: Node, dir_code: int) -> Vector2:
	# Obtain the door positions (in tile coordinates) for current room and the neighbor.
	var door_current: Vector2 = get_door_value(current_scene, dir_code)
	var door_neighbor: Vector2 = get_door_value(neighbor_scene, opposite_direction[dir_code])
	
	# Compute the direction vector associated with the door connection.
	# Even though our get_door_value returns positions in tile units, we use the direction
	# from the passed code to add a GAP in the proper direction (normalized).
	var vec: Vector2
	match dir_code:
		DIR_TOP:
			vec = Vector2(0, -1)
		DIR_LEFT:
			vec = Vector2(-1, 0)
		DIR_BOTTOM:
			vec = Vector2(0, 1)
		DIR_RIGHT:
			vec = Vector2(1, 0)
		_:
			vec = Vector2.ZERO
	
	# The basic alignment (without gap) is computed as:
	# neighbor_pos = current_pos + (door_current - door_neighbor)*TILE_SIZE
	# Now we add GAP displacement in the connection direction.
	return current_pos + (door_current - door_neighbor) * TILE_SIZE + GAP * vec

#===============================================================================
# PLACE ROOMS
#===============================================================================
func place_rooms(matrix: Array) -> void:
	# Use nodes.size() to determine the total number of rooms.
	var total_rooms = nodes.size()
	
	# Pre-select a scene instance for every room based on its assigned room type.
	# This ensures the scene instance matches the type assigned in 'nodes', 
	# not an assumed index ordering.
	room_scenes.clear()
	for i in range(total_rooms):
		# Get the room's type from its 'nodes' dictionary.
		var room_type: int = nodes[i].type
		# Instantiate the scene based on the room's type.
		var scene_list = ROOM_SCENES[room_type]
		room_scenes[i] = scene_list[randi() % scene_list.size()].instantiate()
	
	# Create a dictionary to map room id -> computed world position (as Vector2).
	# In these positions, the room scene’s top-left corner is considered the origin.
	var room_positions = {}
	# Place the beginning room (room id 0) arbitrarily at (0,0).
	room_positions[0] = Vector2.ZERO
	
	# Use a queue to propagate positions from room to room based on the door constraints.
	var queue = [0]
	while queue.size() > 0:
		var current_id = queue.pop_front()
		var current_scene = room_scenes[current_id]
		var current_pos = room_positions[current_id]
		
		# For every potential neighbor:
		for neighbor_id in range(total_rooms):
			var code = matrix[current_id][neighbor_id]
			if code != 0:
				# We have a connection from current room at current_id to neighbor_id in direction "code".
				var neighbor_scene = room_scenes[neighbor_id]
				var computed_pos = compute_neighbor_position(current_pos, current_scene, neighbor_scene, code)
				# If the neighbor hasn't been placed, set its position.
				if not room_positions.has(neighbor_id):
					room_positions[neighbor_id] = computed_pos
					queue.append(neighbor_id)
				else:
					# If already set, check for conflict and warn if misaligned.
					if room_positions[neighbor_id] != computed_pos:
						push_warning("Conflict detected for room %d alignment. Expected %s but found %s" %
							[neighbor_id, str(room_positions[neighbor_id]), str(computed_pos)])
						# In a full implementation, you might resolve this conflict.
	
	# Now that all room positions are computed, place the instanced room scenes.
	# The computed position represents the room's top-left corner in world space (in pixels).
	for i in range(total_rooms):
		var scene_instance = room_scenes[i]
		# var room_type = nodes[i].type
		
		# Configure door settings based on connections from the matrix.
		var door_config = [false, false, false, false]  # [top, left, bottom, right]
		for j in range(total_rooms):
			var code = matrix[i][j]
			match code:
				DIR_TOP: door_config[0] = true
				DIR_LEFT: door_config[1] = true
				DIR_BOTTOM: door_config[2] = true
				DIR_RIGHT: door_config[3] = true
		
		# Apply door configuration (for door placement/dimension data) and open all doors.
		scene_instance.door_config = door_config
		# scene_instance.room_id = i

		# Compute world position relative to the parent Node2D.
		var world_position = room_positions[i]
		scene_instance.position = world_position
		
		# Defer adding the scene instance as a child so that it gets properly added.
		room_container.call_deferred("add_child", scene_instance)


#===============================================================================
# DRAW CORRIDORS
#===============================================================================
#
# This function iterates over each connection (each edge in the dungeon graph) and
# draws a corridor between the two rooms. It uses the room scenes (which were placed earlier)
# to retrieve the door tile coordinates. For a vertical connection (DIR_TOP/DIR_BOTTOM),
# the corridor floor is drawn as a 2–tile–wide vertical column (using the door tile X coordinate
# and one tile to its right). For horizontal connections the corridor floor is drawn as a 2–tile–high
# horizontal row (using the door tile Y coordinate and one tile below it). Walls are then drawn
# surrounding the floor such that the overall corridor is 4 tiles thick.
#
func draw_corridors() -> void:
	# Iterate over every node.
	for room in nodes:
		var id = room.id
		# Get the corresponding scene instance for this room.
		var scene_a = room_scenes[id]
		# For each neighbor connection:
		for edge in room.neighbors:
			# To avoid drawing duplicate corridors, only process when room.id < neighbor id.
			if id < edge.id:
				var scene_b = room_scenes[edge.id]
				var d = edge.dir  # door direction on room 'id'
				
				# Get door positions (in tile coordinates) from the room scene.
				# We assume that the room scene stores its door offset as a Vector2.
				var door_a_offset: Vector2 = get_door_value(scene_a, d)
				var door_b_offset: Vector2 = get_door_value(scene_b, opposite_direction[d])
				
				# Compute the door world positions in pixels.
				# (Remember: scene_instance.position is the room’s top–left corner in world space.)
				var door_a_world: Vector2 = scene_a.position + door_a_offset * TILE_SIZE
				var door_b_world: Vector2 = scene_b.position + door_b_offset * TILE_SIZE
				
				# Convert world positions to corridor tilemap coordinates (assuming TILE_SIZE)
				var door_a_tile: Vector2 = door_a_world / TILE_SIZE
				var door_b_tile: Vector2 = door_b_world / TILE_SIZE
				
				# Draw corridor floors and walls based on the connection orientation.
				if d == DIR_TOP or d == DIR_BOTTOM:
					# Vertical corridor.
					# For vertical corridors, we use door_a_tile.x as the left floor column.
					# The floor occupies two columns: door_a_tile.x and door_a_tile.x + 1
					var col = int(door_a_tile.x)
					# Determine start and end Y (tile coordinates) of the corridor floor.
					var start_y = int(min(door_a_tile.y, door_b_tile.y))
					var end_y = int(max(door_a_tile.y, door_b_tile.y))
					
					# Draw the floor tiles for the corridor.
					for x in [col, col + 1]:
						for y in range(start_y + 1, end_y ):
							_draw_floor(Vector2i(x, y))
					
					# Draw walls.
					# Vertical sides: one column to the left (col - 1) and one column to the right (col + 2)
					# Skip first to avoid overwriting existing walls. 
					# TODO: Skip last wall. Currently, it overwrites to fix z-issues
					for y in range(start_y + 1, end_y + 1):
						_draw_wall(Vector2i(col - 1, y))
						_draw_wall(Vector2i(col + 2, y))
						
				elif d == DIR_LEFT or d == DIR_RIGHT:
					# Horizontal corridor.
					# For horizontal corridors, we use door_a_tile.y as the top floor row.
					# The floor occupies two rows: door_a_tile.y and door_a_tile.y + 1
					var row = int(door_a_tile.y)
					# Determine start and end X (tile coordinates) of the corridor floor.
					var start_x = int(min(door_a_tile.x, door_b_tile.x))
					var end_x = int(max(door_a_tile.x, door_b_tile.x))
					
					# Draw the floor tiles for the corridor.
					for x in range(start_x + 1, end_x ):
						for y in [row, row + 1]:
							_draw_floor(Vector2i(x, y))
					
					# Draw walls.
					# Horizontal sides: one row above (row - 1) and one row below (row + 2)
					# Skip first and last column to avoid overwriting existing walls
					for x in range(start_x + 1, end_x):
						_draw_wall(Vector2i(x, row - 1))
						_draw_wall(Vector2i(x, row + 2))

#===============================================================================
# HELPER DRAW FUNCTIONS (for corridors)
#===============================================================================
func _draw_floor(coords: Vector2i):
	corridor_tilemap.set_cell(coords, 0, Vector2i(0,0))

func _draw_wall(coords: Vector2i):
	corridor_wall_tilemap.set_cell(coords, 1, Vector2i(0,0))
