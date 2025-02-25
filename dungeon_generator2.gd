extends Node2D

var floor: TileMapLayer

const REGULAR_TILE := Vector2i(0, 0)
const START_TILE := Vector2i(0, 1)
const END_TILE := Vector2i(1, 1)

func generate_dungeon() -> void:
	floor.clear()
	
	# Constants for room generation
	const ROOM_SIZE := 7
	const ROOM_SPACING := 5
	const GRID_SIZE := 4
	const TOTAL_CELL_SIZE := ROOM_SIZE + ROOM_SPACING
	const CORRIDOR_WIDTH := 3
	const NUM_ROOMS := 10
	
	# Create a 2D array to track which rooms are active
	var active_rooms = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(false)
		active_rooms.append(row)
	
	# Select exactly NUM_ROOMS that are adjacent to each other
	select_adjacent_rooms(active_rooms, NUM_ROOMS)
	
	# Create a graph representation to track connections between rooms
	var connections = {}
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if active_rooms[y][x]:
				connections[Vector2i(x, y)] = []
	
	# Connect only directly adjacent active rooms
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if active_rooms[y][x]:
				var room = Vector2i(x, y)
				
				# Check each adjacent room
				var adjacents = [
					Vector2i(x+1, y),  # Right
					Vector2i(x-1, y),  # Left
					Vector2i(x, y+1),  # Down
					Vector2i(x, y-1)   # Up
				]
				
				for adj in adjacents:
					if is_valid_position(adj, GRID_SIZE) and active_rooms[adj.y][adj.x]:
						if not connections.has(room):
							connections[room] = []
						if not connections.has(adj):
							connections[adj] = []
						connections[room].append(adj)
	
	# Draw the active rooms
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if active_rooms[y][x]:
				draw_room(x, y, ROOM_SIZE, TOTAL_CELL_SIZE)
	
	# Draw corridors between connected rooms
	var processed_connections = []
	for from_room in connections.keys():
		for to_room in connections[from_room]:
			# Avoid processing the same connection twice
			var connection_pair = [from_room, to_room]
			connection_pair.sort()
			if connection_pair in processed_connections:
				continue
			processed_connections.append(connection_pair)
			
			draw_corridor(from_room, to_room, ROOM_SIZE, TOTAL_CELL_SIZE, CORRIDOR_WIDTH)
	
	# Find start and end rooms (farthest apart)
	var active_room_list = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if active_rooms[y][x]:
				active_room_list.append(Vector2i(x, y))
	
	var start_room = Vector2i.ZERO
	var end_room = Vector2i.ZERO
	var max_distance = -1
	
	# Compare all pairs of active rooms to find the farthest pair
	for i in range(active_room_list.size()):
		for j in range(i + 1, active_room_list.size()):
			var room_a = active_room_list[i]
			var room_b = active_room_list[j]
			var distance = manhattan_distance(room_a, room_b)
			
			if distance > max_distance:
				max_distance = distance
				start_room = room_a
				end_room = room_b
	
	# Mark start and end rooms with special tiles
	mark_special_room(start_room, ROOM_SIZE, TOTAL_CELL_SIZE, START_TILE)
	mark_special_room(end_room, ROOM_SIZE, TOTAL_CELL_SIZE, END_TILE)

# Select rooms ensuring they form an adjacent cluster
func select_adjacent_rooms(active_rooms: Array, num_rooms: int) -> void:
	var grid_size = active_rooms.size()
	
	# Start with a random room
	var start_x = randi() % grid_size
	var start_y = randi() % grid_size
	active_rooms[start_y][start_x] = true
	var selected_count = 1
	
	# Keep track of the frontier - rooms adjacent to our selected rooms
	var frontier = []
	add_adjacent_to_frontier(Vector2i(start_x, start_y), grid_size, active_rooms, frontier)
	
	# Continue selecting rooms until we have enough
	while selected_count < num_rooms and frontier.size() > 0:
		# Pick a random room from the frontier
		var index = randi() % frontier.size()
		var next_room = frontier[index]
		frontier.remove_at(index)
		
		# If it's already active, skip it
		if active_rooms[next_room.y][next_room.x]:
			continue
		
		# Activate the room
		active_rooms[next_room.y][next_room.x] = true
		selected_count += 1
		
		# Add its neighbors to the frontier
		add_adjacent_to_frontier(next_room, grid_size, active_rooms, frontier)
	
	# If we couldn't select enough rooms (unlikely with a 4x4 grid trying to place 10 rooms),
	# just fill in remaining slots randomly
	if selected_count < num_rooms:
		var remaining = []
		for y in range(grid_size):
			for x in range(grid_size):
				if not active_rooms[y][x]:
					remaining.append(Vector2i(x, y))
		
		remaining.shuffle()
		for i in range(min(num_rooms - selected_count, remaining.size())):
			var pos = remaining[i]
			active_rooms[pos.y][pos.x] = true

# Helper function to add adjacent cells to the frontier
func add_adjacent_to_frontier(pos: Vector2i, grid_size: int, active_rooms: Array, frontier: Array) -> void:
	var adjacents = [
		Vector2i(pos.x+1, pos.y),  # Right
		Vector2i(pos.x-1, pos.y),  # Left
		Vector2i(pos.x, pos.y+1),  # Down
		Vector2i(pos.x, pos.y-1)   # Up
	]
	
	for adj in adjacents:
		if is_valid_position(adj, grid_size) and not active_rooms[adj.y][adj.x]:
			if not frontier.has(adj):
				frontier.append(adj)

# Check if a position is within the grid bounds
func is_valid_position(pos: Vector2i, grid_size: int) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

# Draw a single room
func draw_room(grid_x: int, grid_y: int, room_size: int, total_cell_size: int) -> void:
	var start_x := grid_x * total_cell_size
	var start_y := grid_y * total_cell_size
	
	# Create each room cell
	for y in range(room_size):
		for x in range(room_size):
			var coords := Vector2i(start_x + x, start_y + y)
			floor.set_cell(coords, 0, REGULAR_TILE, 0)

# Draw a corridor between two rooms
func draw_corridor(from_room: Vector2i, to_room: Vector2i, room_size: int, total_cell_size: int, corridor_width: int) -> void:
	var from_center_x = from_room.x * total_cell_size + room_size / 2
	var from_center_y = from_room.y * total_cell_size + room_size / 2
	var to_center_x = to_room.x * total_cell_size + room_size / 2
	var to_center_y = to_room.y * total_cell_size + room_size / 2
	
	# Determine if rooms are adjacent horizontally or vertically
	if from_room.x == to_room.x:  # Vertical connection
		var start_y = min(from_center_y, to_center_y)
		var end_y = max(from_center_y, to_center_y)
		var x = from_center_x
		
		# Draw vertical corridor
		for y in range(start_y, end_y + 1):
			for offset in range(-corridor_width/2, corridor_width/2 + 1):
				floor.set_cell(Vector2i(x + offset, y), 0, REGULAR_TILE, 0)
	
	elif from_room.y == to_room.y:  # Horizontal connection
		var start_x = min(from_center_x, to_center_x)
		var end_x = max(from_center_x, to_center_x)
		var y = from_center_y
		
		# Draw horizontal corridor
		for x in range(start_x, end_x + 1):
			for offset in range(-corridor_width/2, corridor_width/2 + 1):
				floor.set_cell(Vector2i(x, y + offset), 0, REGULAR_TILE, 0)

# Calculate Manhattan distance between two points
func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# Mark a room with a special tile (START_TILE or END_TILE)
func mark_special_room(room: Vector2i, room_size: int, total_cell_size: int, special_tile: Vector2i) -> void:
	var start_x := room.x * total_cell_size
	var start_y := room.y * total_cell_size
	
	# Mark the center of the room with the special tile
	var center_x = start_x + room_size / 2
	var center_y = start_y + room_size / 2
	floor.set_cell(Vector2i(center_x, center_y), 0, special_tile, 0)
