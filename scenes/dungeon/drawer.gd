class_name DungeonCorridorDrawer

var corridor_tilemap: TileMapLayer
var corridor_wall_tilemap: TileMapLayer
var tile_size: int = 16

func _init(_corridor_tilemap: TileMapLayer, _corridor_wall_tilemap: TileMapLayer):
	corridor_tilemap = _corridor_tilemap
	corridor_wall_tilemap = _corridor_wall_tilemap
	tile_size = _corridor_tilemap.tile_set.tile_size.x

func draw_all_corridors(rooms: Array[Dungen.Room], room_scenes: Array[RoomBase]) -> void:
	# Iterate over every node.
	for idx in range(rooms.size()):
		var room: Dungen.Room = rooms[idx]
		var scene_a: RoomBase = room_scenes[idx]
		
		for neighbour_idx in room.get_tlbr_neighbours():
			if idx < neighbour_idx:
				var scene_b: RoomBase = room_scenes[neighbour_idx]
				var d: int = room.get_neighbour_direction(neighbour_idx)
				
				var door_a_offset: Vector2 = Dungen.get_door_value(scene_a, d)
				var door_b_offset: Vector2 = Dungen.get_door_value(scene_b, Dungen.opposite_direction[d])
				
				var door_a_world: Vector2 = scene_a.position + door_a_offset * tile_size
				var door_b_world: Vector2 = scene_b.position + door_b_offset * tile_size
				
				var door_a_tile: Vector2i = Vector2i(door_a_world / tile_size)
				var door_b_tile: Vector2i = Vector2i(door_b_world / tile_size)
				
				_draw_corridor_between_points(door_a_tile, door_b_tile)

func draw_room_corridors(room: Dungen.Room, room_scenes: Array[RoomBase]) -> void:
	# Iterate over every node.
	var scene: RoomBase = room_scenes[room.id]
	for neighbour_idx in room.get_tlbr_neighbours():
		if room.id < neighbour_idx:
			var scene_b: RoomBase = room_scenes[neighbour_idx]
			var d: int = room.get_neighbour_direction(neighbour_idx)
			var is_vertical : bool = d == Dungen.Direction.TOP or d == Dungen.Direction.BOTTOM
			
			var door_a_offset: Vector2 = Dungen.get_door_value(scene, d)
			var door_b_offset: Vector2 = Dungen.get_door_value(scene_b, Dungen.opposite_direction[d])
			
			var door_a_world: Vector2 = scene.position + door_a_offset * tile_size
			var door_b_world: Vector2 = scene_b.position + door_b_offset * tile_size
			
			var door_a_tile: Vector2i = Vector2i(door_a_world / tile_size)
			var door_b_tile: Vector2i = Vector2i(door_b_world / tile_size)
			
			_draw_corridor_between_points(door_a_tile, door_b_tile, 1 if is_vertical else 0)

func _clear_corridors() -> void:
	corridor_tilemap.clear()
	corridor_wall_tilemap.clear()

func _draw_corridor_between_points(point_a: Vector2i, point_b: Vector2i, is_vertical: int = -1) -> void:
	# Check if the points are aligned (share an x or y coordinate)
	if point_a.x == point_b.x or point_a.y == point_b.y:
		# Aligned corridor - draw directly
		var _is_vertical: bool = point_a.x == point_b.x
		if is_vertical != -1:
			_is_vertical = is_vertical
		var length: int = point_b.y - point_a.y if _is_vertical else point_b.x - point_a.x
		_draw_straight_corridor(point_a, length, [0,0,0,0], _is_vertical)
	else:
		# Non-aligned corridor - create three segments with a bend
		var mid_x: int = (point_a.x + point_b.x) / 2
		var mid_y: int = (point_a.y + point_b.y) / 2
		
		# Determine which quadrant point_b is in relative to point_a
		# Q1: x > 0, y < 0 (top right)
		# Q2: x < 0, y < 0 (top left)
		# Q3: x < 0, y > 0 (bottom left)
		# Q4: x > 0, y > 0 (bottom right)
		var x_direction: int = 1 if point_b.x > point_a.x else -1
		var direction: int = 1 if point_b.y > point_a.y else -1
		var quadrant: int
		if x_direction > 0:
			quadrant = 1 if direction < 0 else 4
		else:
			quadrant = 2 if direction < 0 else 3
		if abs(point_a.x - point_b.x) > abs(point_a.y - point_b.y) or is_vertical == 0:
			# Longer in x direction - make horizontal corridors at ends and vertical in the middle
			var h1_length: int = abs(mid_x - point_a.x) + 2
			var v_length: int = abs(point_b.y - point_a.y) + 1
			var h2_length: int = abs(point_b.x - mid_x) + 1
			
			# Determine shifts based on quadrant
			var skip_1: Array[int] = [0,0,0,0]
			var skip_2: Array[int] = [0,0,0,0]
			var skip_3: Array[int] = [0,0,0,0]
			match quadrant:
				1: # top right
					skip_1[1] = 3
					skip_2 = [0,3,0,3]
					skip_3[3] = 3
				2: # top left
					skip_1[0] = 3
					skip_2 = [3,0,3,0]
					skip_3[2] = 3
				3: # bottom left
					skip_1[3] = 3
					skip_2 = [0,3,0,3]
					skip_3[1] = 3
				4: # bottom right
					skip_1[2] = 3
					skip_2 = [3,0,3,0]
					skip_3[0] = 3
			
			# Create first horizontal segment
			_draw_straight_corridor(point_a, h1_length * x_direction, skip_1, false)
			
			# Create middle vertical segment
			var mid_point_offset: int = 0 if direction > 0 else 1
			var mid_point: Vector2i = Vector2i(mid_x if x_direction > 0 else mid_x - 1, point_a.y + mid_point_offset)
			_draw_straight_corridor(mid_point, v_length * direction, skip_2, true)
			
			# Create second horizontal segment
			_draw_straight_corridor(point_b, h2_length * -x_direction, skip_3, false)
		else:
			# Longer in y direction - make vertical corridors at ends and horizontal in the middle
			var v1_length: int = abs(mid_y - point_a.y) + 2
			var h_length: int = abs(point_b.x - point_a.x) + 1
			var v2_length: int = abs(point_b.y - mid_y) + 1
			
			# Determine shifts based on quadrant
			var skip_1 : Array[int] = [0,0,0,0]
			var skip_2 : Array[int] = [0,0,0,0]
			var skip_3 : Array[int] = [0,0,0,0]
			match quadrant:
				1: # top right
					skip_1[1] = 3
					skip_2 = [0,3,0,3]
					skip_3[3] = 3
				2: # top left
					skip_1[0] = 3
					skip_2 = [3,0,3,0]
					skip_3[2] = 3
				3: # bottom left
					skip_1[3] = 3
					skip_2 = [0,3,0,3]
					skip_3[1] = 3
				4: # bottom right
					skip_1[2] = 3
					skip_2 = [3,0,3,0]
					skip_3[0] = 3
			
			# Create first vertical segment with shifted skip_wall_tlrbrl
			_draw_straight_corridor(point_a, v1_length * direction, skip_1, true)
			
			# Create middle horizontal segment with shifted skip_wall_tlrbrl
			var mid_point_offset : int = 0 if x_direction > 0 else 1
			var mid_point: Vector2i = Vector2i(point_a.x + mid_point_offset, mid_y if direction > 0 else mid_y - 1)
			_draw_straight_corridor(mid_point, h_length * x_direction, skip_2, false)
			
			# Create second vertical segment with shifted skip_wall_tlrbrl
			_draw_straight_corridor(point_b, v2_length * -direction, skip_3, true)

func _draw_straight_corridor(point_a: Vector2i, length: int, skip_wall_tlrbrl: Array[int] = [0,0,0,0], is_vertical: bool = false) -> void:
	# Handle negative length by adjusting start and end points
	var abs_length: int = abs(length)
	var start_point: Vector2i = point_a
	if length < 0:
		if is_vertical:
			start_point.y += length
		else:
			start_point.x += length
	
	if is_vertical:
		# Vertical corridor
		var col: int = start_point.x
		var start_y: int = start_point.y
		var end_y: int = start_y + abs_length
		
		# Draw the floor tiles
		for x in [col, col + 1]:
			for y in range(start_y, end_y + 1):
				_draw_floor(Vector2i(x, y))
		
		# Draw walls
		for y in range(start_y, end_y + 1):
			var left_wall := Vector2i(col - 1, y)
			var right_wall := Vector2i(col + 2, y)
			var i = y - start_y
			var end_i = end_y - start_y
			if i >= skip_wall_tlrbrl[0] and i <= end_i - skip_wall_tlrbrl[3]:
				_draw_wall(left_wall)
			if i >= skip_wall_tlrbrl[1] and i <= end_i - skip_wall_tlrbrl[2]:
				_draw_wall(right_wall)
	else:
		# Horizontal corridor
		var row: int = start_point.y
		var start_x: int = start_point.x
		var end_x: int = start_x + abs_length
		
		# Draw the floor tiles
		for x in range(start_x, end_x + 1):
			for y in [row, row + 1]:
				_draw_floor(Vector2i(x, y))
		
		# Draw walls
		for x in range(start_x, end_x + 1):
			var top_wall := Vector2i(x, row - 1)
			var bottom_wall := Vector2i(x, row + 2)
			var i = x - start_x
			var end_i = end_x - start_x
			if i >= skip_wall_tlrbrl[0] and i <= end_i - skip_wall_tlrbrl[1]:
				_draw_wall(top_wall)
			if i >= skip_wall_tlrbrl[3] and i <= end_i - skip_wall_tlrbrl[2]:
				_draw_wall(bottom_wall)

func _draw_floor(coords: Vector2i):
	corridor_tilemap.set_cell(coords, 0, Vector2i(0,0))

func _draw_wall(coords: Vector2i):
	corridor_wall_tilemap.set_cell(coords, 1, Vector2i(0,0))
