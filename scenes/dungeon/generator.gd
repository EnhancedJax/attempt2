extends Node2D

var rooms : Array[Dungen.Room] = []
var room_scenes : Array[RoomBase] = []

func generate() -> void:
	var graph_builder = DungeonGraphBuilder.new()
	var placer = DungeonRoomPlacer.new(self, $FloorTileLayer.tile_set.tile_size.x, 20)
	var drawer = DungeonCorridorDrawer.new($FloorTileLayer, $WallTileLayer)

	# rooms = graph_builder.generate()
	# graph_builder.print_dungeon()
	# room_scenes = placer.place_rooms(rooms)
	# drawer.draw_corridors(rooms, room_scenes)

	# Test: TLBR corridor skips
	# drawer._draw_straight_corridor(Vector2i(0,0), 10, [1,2,3,4], true)
	# drawer._draw_straight_corridor(Vector2i(10,0), -10, [1,2,3,4], true)

	# Test: longer in y mis-alignment (negative y direction goes up)
	# drawer._draw_corridor_between_points(Vector2i(0,0), Vector2i(5,-10)) # quadrant 1
	# drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(-10,0), Vector2i(-5,-10) + Vector2i(-10,0)) # quadrant 2
	# drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(20,0), Vector2i(-5,10) + Vector2i(20,0)) # quadrant 3
	# drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(30,0), Vector2i(5,10) + Vector2i(30,0)) # quadrant 4

	# Test: longer in x mis-alignment
	drawer._draw_corridor_between_points(Vector2i(0,0), Vector2i(10,-5)) # quadrant 1
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(-10,0), Vector2i(-10,-5) + Vector2i(-10,0)) # quadrant 2
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(20,0), Vector2i(-10,5) + Vector2i(20,0)) # quadrant 3
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(30,0), Vector2i(10,5) + Vector2i(30,0)) # quadrant 4
