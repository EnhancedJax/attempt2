class_name HUD extends Control


@onready var heart_container: HBoxContainer = $HeartConainer
@onready var heart : Control = $HeartConainer/Heart
@onready var weapon_texture: TextureRect = $WeaponContainer/MarginContainer/AspectRatioContainer/TextureRect
const heart_full_texture = preload('res://hud/heart_full_color.tres')
const heart_half_texture = preload('res://hud/heart_half_color.tres')
const title = preload("res://hud/title/title.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# MINIMAP SETTINGS & STATE
# ─────────────────────────────────────────────────────────────────────────────

# How much pixels one grid cell in the dungeon corresponds to.
const MINIMAP_SCALE := 100

# Each room is drawn as a square.
const ROOM_SIZE_MINIMAP := 64 

# (Optional) A margin offset if you want to nudge everything.
const MINIMAP_MARGIN := 100

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

var current_max: int = 0  # store previous max health

func _ready() -> void:
	Main.register_hud(self)
	show_title('Test!')

func update_health(value: int = 1, max: int = 1):
	# Update hearts if max changed
	if max != current_max:
		var hearts_needed = int(ceil(max / 2.0))
		var current_hearts = heart_container.get_child_count()
		# Add new hearts if fewer than needed
		while current_hearts < hearts_needed:
			var new_heart = heart.duplicate()
			heart_container.add_child(new_heart)
			current_hearts += 1
		# Remove hearts if more than needed
		while current_hearts > hearts_needed:
			heart_container.get_child(current_hearts - 1).queue_free()
			current_hearts -= 1
		current_max = max
	
	# Update each heart's appearance based on current value
	for i in range(heart_container.get_child_count()):
		var hp_in_heart = clamp(value - (i * 2), 0, 2)
		var heart_node = heart_container.get_child(i)
		var icon = heart_node.get_child(1)
		if hp_in_heart == 2:
			icon.texture = heart_full_texture
			icon.visible = true
		elif hp_in_heart == 1:
			icon.texture = heart_half_texture
			icon.visible = true
		else:
			icon.visible = false

func update_equipped_weapon(weapon: Lookup.WeaponType):
	weapon_texture.texture = Lookup.get_weapon_texture(-1, weapon)

func show_title(str: String):
	var scene = title.instantiate()
	scene.set_text(str)
	add_child(scene)

# You must assign or preload a font resource for text drawing.
var minimap_font = preload("res://pending_assets/Fonts/minecraft_font.ttf")

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
	
	# Mark all of its neighbors as discovered.
	# (Even if the player hasn’t visited them, we at least show them in a faint state.)
	var current_room = minimap_nodes[current_room_index]
	for neighbor in current_room.neighbors:
		print('The room ' + str(current_room_index) + ' has a neighbor ' + str(neighbor.id))
		# Each neighbor is a dictionary with key "id"
		if not minimap_unvisited_neighbors.has(neighbor.id):
			minimap_unvisited_neighbors.append(neighbor.id)
	
	# Redraw the minimap.
	queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
# THE _draw CALLBACK – VISUALIZE THE MINIMAP
# ─────────────────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Draw black background container first
	var container_margin = Vector2(50, 50)  # Extra margin around the minimap
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	# Find bounds of all visible rooms
	for room in minimap_nodes:
		if _is_room_visible(room.id):
			var pos = minimap_nodes_positions[room.id]
			min_pos.x = min(min_pos.x, pos.x)
			min_pos.y = min(min_pos.y, pos.y)
			max_pos.x = max(max_pos.x, pos.x + ROOM_SIZE_MINIMAP)
			max_pos.y = max(max_pos.y, pos.y + ROOM_SIZE_MINIMAP)
	
	# Draw the container with margin
	var container_rect = Rect2(
		min_pos - container_margin,
		(max_pos - min_pos) + (container_margin * 2)
	)
	draw_rect(container_rect, Color(0, 0, 0, 0.5), true)

	# Draw corridors (edges) first so that they appear behind the rooms.
	_draw_minimap_corridors()
	
	# Draw each room
	_draw_minimap_rooms()

# Helper: Draw the corridors (dungeon graph edges)
func _draw_minimap_corridors() -> void:
	# Iterate over every room.
	for room in minimap_nodes:
		var room_id = room.id
		# Only draw corridors from a room to those with a higher id to avoid duplicates.
		for edge in room.neighbors:
			if room_id < edge.id:
				# Only draw this corridor if both rooms end up visible on the minimap.
				# (Visibility is defined by whether the room has been visited or is adjacent
				# to a visited room; see _is_room_visible().)
				if _is_room_visible(room_id) and _is_room_visible(edge.id):
					var pos_a = minimap_nodes_positions[room_id] + Vector2(ROOM_SIZE_MINIMAP/2, ROOM_SIZE_MINIMAP/2)
					var pos_b = minimap_nodes_positions[edge.id] + Vector2(ROOM_SIZE_MINIMAP/2, ROOM_SIZE_MINIMAP/2)
					# Draw a line between the room centers with white color (alpha=0.5)
					draw_line(pos_a, pos_b, Color(1, 1, 1, 0.5), 10)


# Helper: Draw each room as a white square with the corresponding room label.
func _draw_minimap_rooms() -> void:
	for room in minimap_nodes:
		var room_id = room.id
		# Check if the room should be drawn.
		if not _is_room_visible(room_id):
			continue
		
		# Determine the opacity for this room.
		var opacity = _get_room_opacity(room_id, room)
		
		# Set the room color (transparent white). We use the computed opacity.
		var color = Color(1,1,1, opacity)
		
		# Get the top‑left position for this room.
		var pos = minimap_nodes_positions[room_id]
		var rect = Rect2(pos, Vector2(ROOM_SIZE_MINIMAP, ROOM_SIZE_MINIMAP))
		
		# Draw a filled rectangle.
		draw_rect(rect, color, true)
		
		# Draw an outline (optional).
		draw_rect(rect, Color(1,1,1, opacity), false, 1)
		
		# Draw the room label at the center.
		var label = room_labels.get(room.type, "?")
		var text_size = minimap_font.get_string_size(label)
		var text_pos = pos + Vector2((ROOM_SIZE_MINIMAP - text_size.x) / 2, (ROOM_SIZE_MINIMAP + text_size.y) / 2)
		draw_string(minimap_font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER)


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


# Compute the opacity for a given room:
#   - 0.9 if it is the current room.
#   - 0.7 if it has been visited/explored.
#   - 0.3 if it wasn’t visited but is adjacent to a visited room.
func _get_room_opacity(room_id: int, room: Dictionary) -> float:
	if room_id == minimap_current:
		return 0.9
	elif minimap_visited.has(room_id):
		return 0.7
	else:
		return 0.3
