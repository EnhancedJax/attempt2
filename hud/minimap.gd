extends Control

# ─────────────────────────────────────────────────────────────────────────────
# MINIMAP SETTINGS & STATE
# ─────────────────────────────────────────────────────────────────────────────

# How much pixels one grid cell in the dungeon corresponds to. Visually shows gap between rooms (scale - size) px
const MINIMAP_SCALE : int =  20

# Each room is drawn as a square.
const ROOM_SIZE_MINIMAP : int =  16
const MINIMAP_CORRIDOR_WIDTH : int =  2

# (Optional) A margin offset if you want to nudge everything.
const MINIMAP_MARGIN : int =  0

# A lookup for room type labels.
# (Assumes your RoomType enum in the main dungeon script is: B=0, E=1, L=2, S=3, F=4)
var room_labels = {
	0: "B",
	1: "E",
	2: "L",
	3: "S",
	4: "F"
}

# Global state that the minimap uses to control what is visible.
var minimap_nodes = []         # The complete list of dungeon nodes (stored from the dungeon generator)
var minimap_nodes_positions = {}   # Dictionary: room_id (int) -> Vector2 (screen position)
var minimap_visited = {}       # Dictionary: room_id -> true (rooms the player has visited/explored)
var minimap_unvisited_neighbors = []  # List of room IDs that are neighbors of visited rooms but haven't been visited yet
var minimap_current : int = -1 # The currently active room id

# You must assign or preload a font resource for text drawing.
var minimap_font = preload("res://pending_assets/Fonts/minecraft_font.ttf")

const MINIMAP_TILE = preload("res://hud/minimap/minimap_tile.tscn")
const MINIMAP_CORRIDOR = preload("res://hud/minimap/minimap_corridor.tscn")

@onready var positioner = $Positioner

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC FUNCTIONS TO INITIALIZE / UPDATE THE MINIMAP
# ─────────────────────────────────────────────────────────────────────────────

# Call this function once after generating the dungeon.
func draw_minimap(nodes: Array) -> void:
	# Store the dungeon data for the minimap.
	minimap_nodes = nodes.duplicate()  # duplicate the array reference if needed
	
	# Compute the grid bounds so that all rooms are visible.
	var min_x = INF
	var min_y = INF
	for room in minimap_nodes:
		min_x = min(min_x, room.pos.x)
		min_y = min(min_y, room.pos.y)
	# Use an offset so that the room with minimum (x,y) appears at (0,0)
	var offset = Vector2(-min_x, -min_y)
	
	# Compute screen positions for every room.
	minimap_nodes_positions.clear()
	for room in minimap_nodes:
		# The room.pos is in grid coordinates. Multiply by MINIMAP_SCALE to get a pixel position.
		# You can also add a constant margin if you wish.
		minimap_nodes_positions[ room.id ] = (room.pos + offset) * MINIMAP_SCALE + Vector2(MINIMAP_MARGIN, MINIMAP_MARGIN)
	
	# Set initial state: assume the starting room is room ID 0.
	minimap_current = 0
	minimap_visited.clear()
	minimap_visited[0] = true
	
	# Force the minimap to redraw.
	update_minimap(0)


# Call this whenever the player moves to a new room.
# current_room_index is the room.id of the room that the player is in.
func update_minimap(current_room_index: int) -> void:
	# Update the current room.
	minimap_current = current_room_index
	# Mark the current room as visited.
	minimap_visited[current_room_index] = true
	
	# Mark neighbors as discovered.
	var current_room = minimap_nodes[current_room_index]
	for neighbor in current_room.neighbors:
		print('The room ' + str(current_room_index) + ' has a neighbor ' + str(neighbor.id))
		if not minimap_unvisited_neighbors.has(neighbor.id):
			minimap_unvisited_neighbors.append(neighbor.id)
	
	redraw_minimap()  # call the renamed draw function

# Replaces _draw. Uses scene instancing instead of low-level drawing.
func redraw_minimap() -> void:
	# Clear existing minimap elements.
	for child in positioner.get_children():
		child.queue_free()
	
	# Draw corridors.
	for room in minimap_nodes:
		var room_id = room.id
		for edge in room.neighbors:
			# Avoid duplicating corridors by only drawing one direction.
			if room_id < edge.id:
				if _is_room_visible(room_id) and _is_room_visible(edge.id):
					# Get the center positions of each room.
					var center_a = minimap_nodes_positions[room_id] + Vector2(ROOM_SIZE_MINIMAP/2, ROOM_SIZE_MINIMAP/2)
					var center_b = minimap_nodes_positions[edge.id] + Vector2(ROOM_SIZE_MINIMAP/2, ROOM_SIZE_MINIMAP/2)
					
					# Compute the normalized direction from room A to room B.
					var dir = (center_b - center_a).normalized()
					
					# Offset the start and end positions so the corridor connects from the room edges.
					var start_point = center_a + dir * (ROOM_SIZE_MINIMAP / 2) + dir.orthogonal() * (MINIMAP_CORRIDOR_WIDTH / 2)
					var end_point = center_b - dir * (ROOM_SIZE_MINIMAP / 2) + dir.orthogonal() * (MINIMAP_CORRIDOR_WIDTH / 2)
					
					# Determine the length of the corridor.
					var corridor_length = start_point.distance_to(end_point)
					# Calculate the angle for rotation.
					var angle = (center_b - center_a).angle()

					var corridor_instance = MINIMAP_CORRIDOR.instantiate()
					
					# Set the corridor’s position, size, and rotation.
					# We assume the corridor scene uses its top-left as a pivot, so you might want to adjust its pivot offset in the scene.
					corridor_instance.position = start_point
					corridor_instance.size = Vector2(corridor_length, MINIMAP_CORRIDOR_WIDTH)
					corridor_instance.rotation = angle
					
					positioner.add_child(corridor_instance)
	
	# Draw rooms.
	for room in minimap_nodes:
		var room_id = room.id
		if not _is_room_visible(room_id):
			continue
		
		var tile_instance = MINIMAP_TILE.instantiate()
		tile_instance.position = minimap_nodes_positions[room_id]
		tile_instance.size = Vector2(ROOM_SIZE_MINIMAP, ROOM_SIZE_MINIMAP)
		
		var label = room_labels.get(room.type, "?")
		tile_instance.update_text(label)
		if room_id == minimap_current:
			tile_instance.update_style("current")
		elif minimap_visited.has(room_id):
			tile_instance.update_style("visited")
		else:
			tile_instance.update_style("unvisited")
		
		positioner.add_child(tile_instance)
	
	# Center positioner relative to self by moving it so that the current room is in the center.
	# Get the center position of the current room within the minimap.
	var current_room_center = minimap_nodes_positions[minimap_current] + Vector2(ROOM_SIZE_MINIMAP/2, ROOM_SIZE_MINIMAP/2)
	# Calculate the new position: self.size is the size of the container,
	# so the current room will be centered when its center aligns with self.size / 2.
	positioner.position = self.size / 2 - current_room_center

# ─────────────────────────────────────────────────────────────────────────────
# HELPER FUNCTIONS: VISIBILITY AND OPACITY
# ─────────────────────────────────────────────────────────────────────────────

# Returns true if a room is visible on the minimap.
# A room is visible if it either has been visited (or is the current room) or if
# it is adjacent to one of the visited (or current) rooms.
func _is_room_visible(room_id: int) -> bool:
	# If the room is visited or is the current room, it is visible.
	if minimap_visited.has(room_id) or minimap_unvisited_neighbors.has(room_id):
		return true
	return false
