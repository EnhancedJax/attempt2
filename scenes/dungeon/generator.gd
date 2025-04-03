extends Node2D

func generate() -> Dictionary:
	var graph_builder = DungeonGraphBuilder.new()
	var placer = DungeonRoomPlacer.new(self, $FloorTileLayer.tile_set.tile_size.x, 15)
	var drawer = DungeonCorridorDrawer.new($FloorTileLayer, $WallTileLayer)

	var rooms = graph_builder.generate()
	graph_builder.print_dungeon()
	var room_scenes = placer.place_rooms(rooms)
	drawer.draw_corridors(rooms, room_scenes)
	return {
		"rooms": rooms,
		"room_scenes": placer.room_scenes,
	}
