extends Node2D

var floor: TileMapLayer

const REGULAR_TILE := Vector2i(0, 0)
const START_TILE := Vector2i(0, 1)
const END_TILE := Vector2i(1, 1)
const ROOM_SPACING := 5
const GRID_SIZE := 4
const CORRIDOR_WIDTH := 3
const NUM_ROOMS := 10
var active_rooms : Array = []
# keys:
# 0 - empty
# 1 - enemy room
# 2 - start room
# 3 - end room
# 4 - special room (TBA)
# 5 - boss room (TBA)

func generate_dungeon() -> void:
	floor.clear()
	build_array()
	mark_rooms()
	const start_room = Vector2i(5, 5)
	const end_room = Vector2i(5, 5)
	var room_list = get_room_list()
	var largest_room_dimension = Vector2i(0, 0)
	for room in room_list:
		if room.x > largest_room_dimension.x:
			largest_room_dimension.x = room.x
		if room.y > largest_room_dimension.y:
			largest_room_dimension.y = room.y
			
	
func build_array():
	active_rooms = []
	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			row.append(0)
		active_rooms.append(row)

func mark_rooms():
	# first, randomly select the start room from one of the EDGE rooms
	var picked_edge = randi() % 4
	var start_room = Vector2i(0,0)
	if picked_edge == 0:
		start_room = Vector2i(0, randi() % GRID_SIZE)
	elif picked_edge == 1:
		start_room = Vector2i(randi() % GRID_SIZE, 0)
	elif picked_edge == 2:
		start_room = Vector2i(GRID_SIZE - 1, randi() % GRID_SIZE)
	else:
		start_room = Vector2i(randi() % GRID_SIZE, GRID_SIZE - 1)
	
	# then, randomly traverse through the grid until NUM_ROOMS are marked
	recurse_mark_rooms(start_room, NUM_ROOMS - 1)

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE and pos.y >= 0 and pos.y < GRID_SIZE

func recurse_mark_rooms(pos: Vector2i, num_rooms: int) -> void:
	if num_rooms == 0:
		return
	if num_rooms == NUM_ROOMS - 1:
		active_rooms[pos.y][pos.x] = 2
	var adjacents = [
		Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x - 1, pos.y),
		Vector2i(pos.x, pos.y + 1),
		Vector2i(pos.x, pos.y - 1)
	]
	var picked_direction = randi() % 4
	for i in range(4):
		var adj = adjacents[(picked_direction + i) % 4]
		if is_valid_position(adj) and active_rooms[adj.y][adj.x] == 0:
			active_rooms[adj.y][adj.x] = 1
			recurse_mark_rooms(adj, num_rooms - 1)
			break

func get_room_list():
	return [Vector2i(5, 7), Vector2i(11, 7), Vector2i(9, 7), Vector2i(13, 11)]