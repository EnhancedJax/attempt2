extends Node2D

var rooms : Array[Dungen.Room] = []
var room_scenes : Array[RoomBase] = []
var drawer : DungeonCorridorDrawer = null

var _last_enabled_rooms : Array[RoomBase] = []

func generate() -> void:
	var graph_builder = DungeonGraphBuilder.new()
	var placer = DungeonRoomPlacer.new(self, $FloorTileLayer.tile_set.tile_size.x, 20)
	drawer = DungeonCorridorDrawer.new($FloorTileLayer, $WallTileLayer)

	clear_all_signals()
	rooms = graph_builder.generate()
	graph_builder.print_dungeon()
	room_scenes = placer.place_rooms(rooms) # all rooms are disabled by default.
	Main.hud.draw_minimap(rooms)
	# drawer.draw_corridors(rooms, room_scenes)

	register_all_rooms()
	Main.signal_player_room_changed.connect(_on_player_room_changed)

# Implement only showing neighbouring rooms
func _on_player_room_changed(room_scene: RoomBase) -> void:
	var room_data = room_scene.room_data
	# Get all scenes to enable
	var scenes_to_enable : Array[RoomBase]= [room_scene]
	for i in room_data.get_tlbr_neighbours():
		if i >= 0 and i < room_scenes.size():
			scenes_to_enable.append(room_scenes[i])
	
	print('Last enabled room ids:')
	for r in _last_enabled_rooms:
		print(r.room_data.id)
	print('Current enabled room ids:')
	for r in scenes_to_enable:
		print(r.room_data.id)

	# Find scenes to disable
	for r in _last_enabled_rooms:
		if r not in scenes_to_enable:
			r.disable()
	# Enable scenes that aren't enabled
	drawer._clear_corridors()
	for r in scenes_to_enable:
		if r not in _last_enabled_rooms:
			r.enable()
		drawer.draw_room_corridors(r.room_data, room_scenes)
	_last_enabled_rooms = scenes_to_enable

# /* --- Registering and deregister --- */

func register_all_rooms() -> void:
	for i in self.room_scenes.size():
		var scene = self.room_scenes[i]
	
		scene.signal_player_entered.connect(Main._on_player_room_entered.bind(i, scene))
		scene.signal_room_cleared.connect(Main._on_player_room_cleared)

func clear_all_signals() -> void:
	for i in self.room_scenes.size():
		var scene = self.room_scenes[i]
	
		scene.signal_player_entered.disconnect(Main._on_player_room_entered)
		scene.signal_room_cleared.disconnect(Main._on_player_room_cleared)

# /* -------------- Tests ------------- */

func _draw_test(drawer: DungeonCorridorDrawer) -> void:
	# Test: TLBR corridor skips
	drawer._draw_straight_corridor(Vector2i(0,0), 10, [1,2,3,4], true)
	drawer._draw_straight_corridor(Vector2i(10,0), -10, [1,2,3,4], true)

	# Test: longer in y mis-alignment (negative y direction goes up)
	drawer._draw_corridor_between_points(Vector2i(0,0), Vector2i(5,-10)) # quadrant 1
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(-10,0), Vector2i(-5,-10) + Vector2i(-10,0)) # quadrant 2
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(20,0), Vector2i(-5,10) + Vector2i(20,0)) # quadrant 3
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(30,0), Vector2i(5,10) + Vector2i(30,0)) # quadrant 4

	# Test: longer in x mis-alignment
	drawer._draw_corridor_between_points(Vector2i(0,0), Vector2i(10,-5)) # quadrant 1
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(-10,0), Vector2i(-10,-5) + Vector2i(-10,0)) # quadrant 2
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(20,0), Vector2i(-10,5) + Vector2i(20,0)) # quadrant 3
	drawer._draw_corridor_between_points(Vector2i(0,0) + Vector2i(30,0), Vector2i(10,5) + Vector2i(30,0)) # quadrant 4

# /* ------------ Interals ------------ */
