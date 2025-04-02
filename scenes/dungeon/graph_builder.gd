class_name DungeonGraphBuilder

var _rooms: Array[Dungen.Room]
var _rng: RandomNumberGenerator

func _init():
	_rooms = []
	_rng = RandomNumberGenerator.new()
	_rng.randomize()

func _add_room(type: Dungen.RoomType) -> int:
	print(Dungen)
	var room := Dungen.Room.new()
	room.room_type = type
	_rooms.append(room)
	return _rooms.size() - 1

func _connect_rooms(room1: int, room2: int) -> void:
	_rooms[room1].connected_rooms.append(room2)
	_rooms[room2].connected_rooms.append(room1)
	
	# Find available directions for both rooms
	var directions := [Dungen.Direction.TOP, Dungen.Direction.RIGHT, Dungen.Direction.BOTTOM, Dungen.Direction.LEFT]
	directions.shuffle()
	
	for dir in directions:
		if _can_assign_direction(room1, room2, dir):
			_assign_direction(room1, room2, dir)
			break

func _can_assign_direction(room1: int, room2: int, dir: Dungen.Direction) -> bool:
	var n1: Dungen.Neighbours = _rooms[room1].neighbours
	var n2: Dungen.Neighbours = _rooms[room2].neighbours
	
	match dir:
		Dungen.Direction.TOP:
			return n1.top == -1 and n2.bottom == -1
		Dungen.Direction.RIGHT:
			return n1.right == -1 and n2.left == -1
		Dungen.Direction.BOTTOM:
			return n1.bottom == -1 and n2.top == -1
		Dungen.Direction.LEFT:
			return n1.left == -1 and n2.right == -1
		_:
			return false

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
	_rooms.clear()
	
	# Start room
	var start := _add_room(Dungen.RoomType.ENTRANCE)
	
	# Add 0-2 enemy rooms
	var last_room := start
	var num_enemies := _rng.randi_range(0, 2)
	for i in num_enemies:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		_connect_rooms(last_room, enemy)
		last_room = enemy
	
	# Create loop of 4 rooms
	var loop_rooms: Array[int] = []
	for i in 4:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		loop_rooms.append(enemy)
		if i == 0:
			_connect_rooms(last_room, enemy)
		if i > 0:
			_connect_rooms(loop_rooms[i-1], enemy)
	_connect_rooms(loop_rooms[-1], loop_rooms[0])
	
	# Add loot room
	var loop_connection := _rng.randi_range(1, 3)
	var loot1 := _add_room(Dungen.RoomType.LOOT)
	_connect_rooms(loop_rooms[loop_connection], loot1)
	
	# Hub room
	var hub_connection := (loop_connection + 1) % 4
	var hub := _add_room(Dungen.RoomType.ENEMY)
	_connect_rooms(loop_rooms[hub_connection], hub)
	
	# Boss and exit
	var boss := _add_room(Dungen.RoomType.BOSS)
	var exit := _add_room(Dungen.RoomType.EXIT)
	_connect_rooms(hub, boss)
	_connect_rooms(boss, exit)
	
	# Shop branch
	var hub2 := _add_room(Dungen.RoomType.ENEMY)
	var shop := _add_room(Dungen.RoomType.SHOP)
	_connect_rooms(hub, hub2)
	_connect_rooms(hub2, shop)
	
	# Additional rooms from hub2
	var num_additional := _rng.randi_range(2, 3)
	var last_additional := hub2
	for i in num_additional:
		var enemy := _add_room(Dungen.RoomType.ENEMY)
		_connect_rooms(last_additional, enemy)
		last_additional = enemy
	
	# Second loot room
	var loot2 := _add_room(Dungen.RoomType.LOOT)
	_connect_rooms(last_additional, loot2)
	
	return _rooms

func get_last_result() -> Array[Dungen.Room]:
	return _rooms

func print_dungeon() -> void:
	var size := _rooms.size()
	var matrix: Array[Array] = []
	
	# Initialize matrix
	for i in size:
		var row: Array[int] = []
		for j in size:
			row.append(0)
		matrix.append(row)
	
	# Fill matrix
	for i in size:
		for j in _rooms[i].connected_rooms:
			matrix[i][j] = 1
	
	# Print matrix
	print("Adjacency Matrix:")
	for i in size:
		var row := ""
		for j in size:
			row += str(matrix[i][j]) + " "
		print(row)
