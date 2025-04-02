class_name DungeonCorridorDrawer

var corridor_tilemap: TileMapLayer
var corridor_wall_tilemap: TileMapLayer
var tile_size: int = 16

func _init(_corridor_tilemap: TileMapLayer, _corridor_wall_tilemap: TileMapLayer):
	corridor_tilemap = _corridor_tilemap
	corridor_wall_tilemap = _corridor_wall_tilemap
	tile_size = _corridor_tilemap.tile_set.tile_size.x

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
func draw_corridors(rooms: Array[Dungen.Room], room_scenes: Array[RoomBase]) -> void:
	# Iterate over every node.
	for idx in range(rooms.size()):
		var room = rooms[idx]
		# Get the corresponding scene instance for this room.
		var scene_a = room_scenes[idx]
		# For each neighbor connection:
		for neighbour_idx in room.get_tlbr_neighbours():
			# To avoid drawing duplicate corridors, only process when room.id < neighbor id.
			if idx < neighbour_idx:
				var scene_b = room_scenes[neighbour_idx]
				var d = room.get_neighbour_direction(neighbour_idx)
				
				# Get door positions (in tile coordinates) from the room scene.
				# We assume that the room scene stores its door offset as a Vector2.
				var door_a_offset: Vector2 = Dungen.get_door_value(scene_a, d)
				var door_b_offset: Vector2 = Dungen.get_door_value(scene_b, Dungen.opposite_direction[d])
				
				# Compute the door world positions in pixels.
				# (Remember: scene_instance.position is the room’s top–left corner in world space.)
				var door_a_world: Vector2 = scene_a.position + door_a_offset * tile_size
				var door_b_world: Vector2 = scene_b.position + door_b_offset * tile_size
				
				# Convert world positions to corridor tilemap coordinates (assuming tile_size)
				var door_a_tile: Vector2 = door_a_world / tile_size
				var door_b_tile: Vector2 = door_b_world / tile_size
				
				# Draw corridor floors and walls based on the connection orientation.
				if d == Dungen.DIR_TOP or d == Dungen.DIR_BOTTOM:
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
						
				elif d == Dungen.DIR_LEFT or d == Dungen.DIR_RIGHT:
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

func _draw_floor(coords: Vector2i):
	corridor_tilemap.set_cell(coords, 0, Vector2i(0,0))

func _draw_wall(coords: Vector2i):
	corridor_wall_tilemap.set_cell(coords, 1, Vector2i(0,0))
