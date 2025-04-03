extends Node2D

var rooms : Array[Dungen.Room] = []
var room_scenes : Array[RoomBase] = []

func generate() -> void:
	var graph_builder = DungeonGraphBuilder.new()
	var placer = DungeonRoomPlacer.new(self, $FloorTileLayer.tile_set.tile_size.x, 20)
	var drawer = DungeonCorridorDrawer.new($FloorTileLayer, $WallTileLayer)

	rooms = graph_builder.generate()
	graph_builder.print_dungeon()
	room_scenes = placer.place_rooms(rooms)
	drawer.draw_corridors(rooms, room_scenes)
