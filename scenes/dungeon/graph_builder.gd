class_name DungeonGraphBuilder

var _rooms: Array[Dungen.Room]
var _rng: RandomNumberGenerator
var _flag_regenerate: bool = false

func _init():
	_rooms = []
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func _add_room(type: Dungen.RoomType) -> int:
	var room := Dungen.Room.new()
	room.room_type = type
	_rooms.append(room)
	print("[GraphBuilder] Created new room: %s at index %d" % [Dungen.RoomType.keys()[type], _rooms.size() - 1])
	return _rooms.size() - 1

func _connect_rooms(room1: int, room2: int, forced_direction: Dungen.Direction = -1) -> void:
	print("[GraphBuilder] Attempting to connect room %d to room %d" % [room1, room2])
	var directions: Array[Dungen.Direction]
	if forced_direction != -1:
		directions = [forced_direction]
		print("[GraphBuilder] Using forced direction: %s" % Dungen.Direction.keys()[forced_direction])
	else:
		directions = [Dungen.Direction.TOP, Dungen.Direction.RIGHT, Dungen.Direction.BOTTOM, Dungen.Direction.LEFT]
		directions.shuffle()
		print("[GraphBuilder] Testing shuffled directions: %s" % directions)
	
	for dir in directions:
		if _can_assign_direction(room1, room2, dir):
			print("[GraphBuilder] Successfully connected rooms using direction: %s" % Dungen.Direction.keys()[dir])
			_assign_direction(room1, room2, dir)
			_update_grid_position(room2, room1, dir)
			return
	
	print("[GraphBuilder] WARNING: Failed to connect rooms %d and %d" % [room1, room2])
	_flag_regenerate = true

func _update_grid_position(new_room: int, base_room: int, dir: Dungen.Direction) -> void:
	var new_pos: Vector2i = _rooms[base_room].get_neighbor_position(dir)
	_rooms[new_room].grid_position = new_pos

func _can_assign_direction(room1: int, room2: int, dir: Dungen.Direction) -> bool:
	var n1: Dungen.Neighbours = _rooms[room1].neighbours
	var n2: Dungen.Neighbours = _rooms[room2].neighbours
	
	var basic_check: bool = false
	match dir:
		Dungen.Direction.TOP: basic_check = n1.top == -1 and n2.bottom == -1
		Dungen.Direction.RIGHT: basic_check = n1.right == -1 and n2.left == -1
		Dungen.Direction.BOTTOM: basic_check = n1.bottom == -1 and n2.top == -1
		Dungen.Direction.LEFT: basic_check = n1.left == -1 and n2.right == -1
	
	if not basic_check:
		return false
	
	var new_pos : Vector2i = _rooms[room1].get_neighbor_position(dir)
	
	# Check if any room occupies the target position
	for i in _rooms.size():
		if _rooms[i].grid_position == new_pos:
			# Allow connection if the room at target position is room2
			return i == room2
	
	return true

func _get_new_position(base_pos: Vector2i, dir: Dungen.Direction) -> Vector2i:
	match dir:
		Dungen.Direction.TOP:
			return base_pos + Vector2i(0, -1)
		Dungen.Direction.RIGHT:
			return base_pos + Vector2i(1, 0)
		Dungen.Direction.BOTTOM:
			return base_pos + Vector2i(0, 1)
		Dungen.Direction.LEFT:
			return base_pos + Vector2i(-1, 0)
	return base_pos

func _assign_direction(room1: int, room2: int, dir: Dungen.Direction) -> void:
	match dir:
		Dungen.Direction.TOP:
			_rooms[room1].neighbours.top = room2
			_rooms[room2].neighbours.bottom = room1
		Dungen.Direction.RIGHT:
			_rooms[room1].neighbours.right = room2
			_rooms[room2].neighbours.left = room1
		Dungen.Direction.BOTTOM:
			_rooms[room1].neighbours.bottom = room2
			_rooms[room2].neighbours.top = room1
		Dungen.Direction.LEFT:
			_rooms[room1].neighbours.left = room2
			_rooms[room2].neighbours.right = room1

func generate() -> Array[Dungen.Room]:
	print("[GraphBuilder] Starting dungeon generation")
	_rooms.clear()
	_flag_regenerate = false
	
	var start := _add_room(Dungen.RoomType.ENTRANCE)
	print("[GraphBuilder] Created entrance room at (0,0)")
	
	var last_room := start
	var num_enemies := _rng.randi_range(0, 2)
	print("[GraphBuilder] Generating initial path with %d enemy rooms" % num_enemies)
	for i in num_enemies:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		_connect_rooms(last_room, enemy)
		last_room = enemy
	
	# Modified loop generation to ensure proper spacing
	var loop_rooms: Array[int] = []
	var loop_directions := [
		Dungen.Direction.RIGHT,
		Dungen.Direction.BOTTOM,
		Dungen.Direction.LEFT,
		Dungen.Direction.TOP
	]
	
	# Create first loop room with explicit connection
	var first_loop := _add_room(Dungen.RoomType.ENEMY)
	_connect_rooms(last_room, first_loop, Dungen.Direction.RIGHT)
	loop_rooms.append(first_loop)
	
	# Create remaining loop rooms with forced directions
	for i in 3:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		_connect_rooms(loop_rooms[i], enemy, loop_directions[i])
		loop_rooms.append(enemy)
	
	print("[GraphBuilder] Creating loop with %d rooms" % loop_rooms.size())
	print("[GraphBuilder] Connecting loop back to start")
	if _can_assign_direction(loop_rooms[-1], loop_rooms[0], loop_directions[-1]):
		_assign_direction(loop_rooms[-1], loop_rooms[0], loop_directions[-1])
		print("[GraphBuilder] Successfully closed the loop")
	else:
		print("[GraphBuilder] Failed to close the loop")
	
	# Continue with the rest of the generation
	print("[GraphBuilder] Generating final section of dungeon")
	var loop_connection := _rng.randi_range(1, 2)  # Changed from (1,3) to avoid potential overlaps
	var loot1 := _add_room(Dungen.RoomType.LOOT)
	_connect_rooms(loop_rooms[loop_connection], loot1)
	
	var hub_connection := (loop_connection + 2) % 4  # Changed to ensure more space between connections
	var hub := _add_room(Dungen.RoomType.ENEMY)
	_connect_rooms(loop_rooms[hub_connection], hub)
	
	var boss := _add_room(Dungen.RoomType.BOSS)
	var exit := _add_room(Dungen.RoomType.EXIT)
	_connect_rooms(hub, boss)
	_connect_rooms(boss, exit)
	
	var hub2 := _add_room(Dungen.RoomType.ENEMY)
	var shop := _add_room(Dungen.RoomType.SHOP)
	_connect_rooms(hub, hub2)
	_connect_rooms(hub2, shop)
	
	var num_additional := _rng.randi_range(2, 3)
	var last_additional := hub2
	for i in num_additional:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		_connect_rooms(last_additional, enemy)
		last_additional = enemy
	
	var loot2 := _add_room(Dungen.RoomType.LOOT)
	_connect_rooms(last_additional, loot2)
	
	if _flag_regenerate:
		print("[GraphBuilder] Regeneration flag set, retrying dungeon generation")
		return generate()
	print("[GraphBuilder] Dungeon generation complete with %d total rooms" % _rooms.size())
	return _rooms

func get_last_result() -> Array[Dungen.Room]:
	return _rooms
	
func _get_room_letter(room: Dungen.Room, idx: int) -> String:
	match room.room_type:
		Dungen.RoomType.ENTRANCE: return "E"
		Dungen.RoomType.ENEMY: return ("%X" % idx).to_lower() 
		Dungen.RoomType.LOOT: return "L"
		Dungen.RoomType.SHOP: return "S"
		Dungen.RoomType.BOSS: return "B"
		Dungen.RoomType.EXIT: return "X"
		_: return "?"

func print_dungeon() -> void:
	var size := _rooms.size()
	var matrix: Array[Array] = []
	
	for i in size:
		var row: Array[int] = []
		for j in size:
			row.append(0)
		matrix.append(row)
	
	for i in size:
		for neighbor in _rooms[i].get_tlbr_neighbours():
			if neighbor != -1:
				matrix[i][neighbor] = 1
	
	print("Adjacency Matrix:")
	for i in size:
		var row := ""
		for j in size:
			row += str(matrix[i][j]) + " "
		print(row)
	
	print("Node and neighbours")
	for i in size:
		var neighbours := _rooms[i].get_tlbr_neighbours()
		var letter := _get_room_letter(_rooms[i], i)
		print("Node ", i, "(", letter, ") Neighbours: ", neighbours)

	print("Dungeon layout:")
	# Determine grid bounds
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for room in _rooms:
		min_x = min(min_x, room.grid_position.x)
		max_x = max(max_x, room.grid_position.x)
		min_y = min(min_y, room.grid_position.y)
		max_y = max(max_y, room.grid_position.y)

	# Create dictionaries for rooms and connections
	var layout: Dictionary = {}
	var horizontal_connections: Dictionary = {}
	var vertical_connections: Dictionary = {}

	# Map rooms and find connections
	for room_id in _rooms.size():
		var room := _rooms[room_id]
		var letter := _get_room_letter(room, room_id)
		layout[room.grid_position] = letter

		# Store connections
		if room.neighbours.right != -1:
			horizontal_connections[room.grid_position] = true
		if room.neighbours.bottom != -1:
			vertical_connections[room.grid_position] = true

	# Print grid with connections
	for y in range(min_y, max_y + 1):
		# Print room row
		var room_line := ""
		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			room_line += layout.get(pos, " ")
			# Add horizontal connection
			if horizontal_connections.has(pos):
				room_line += "-"
			else:
				room_line += " "
		print(room_line)
		
		# Print vertical connections
		var connection_line := ""
		for x in range(min_x, max_x + 1):
			var pos := Vector2i(x, y)
			if vertical_connections.has(pos):
				connection_line += "|"
			else:
				connection_line += " "
			connection_line += " "  # Space for horizontal alignment
		print(connection_line)
