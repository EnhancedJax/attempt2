@tool

class_name DungeonGenerator extends Node2D

@export var trigger: int = 1:
	set(value):
		generate_dungeon()
var n : int = 6 # number of enemy rooms
var m : int = 2 # number of loot rooms
@onready var debug_label : Label = $Label

var ROOM_B: Node = preload("res://scenes/rooms/room_base.tscn").instantiate()
var ROOM_L: Node = preload("res://scenes/rooms/room_base.tscn").instantiate()
var ROOM_E: Node = preload("res://scenes/rooms/room_base.tscn").instantiate()
var ROOM_S: Node = preload("res://scenes/rooms/room_base.tscn").instantiate()
var ROOM_F: Node = preload("res://scenes/rooms/room_base.tscn").instantiate()

# Create an array to hold nodes.
# Each node is represented as a dictionary with a room "name" : String, "scene" : Node, "world_grid" : Vector2i
# We will refer to nodes via their index in this array.
var nodes = []
# We will store connections as Vector3i objects.
# x, y are the indices of connected nodes, z is the direction (0=top,1=left,2=bottom,3=right)
var edges: Array[Vector3i] = []



func generate_dungeon() -> void:
	randomize()
	reset()
	n = 6
	m = 2
	print_label("Generating dungeon with %d enemies and %d loot rooms" % [n, m])
	generate_dungeon_graph()
	# assign_room_world_grid()
	# carve_entrances()
	# place_rooms()
	# draw_cooridors()

# func set_tile(x: int, y: int) -> void:
# 	floor.set_cell(Vector2i(x, y), 0, Vector2i(0,0), 0)

func reset():
	nodes.clear()
	grid.clear()
	room_positions.clear()
	edges.clear()
	debug_label.text = ""
	
# Helper function to check if a position is valid
func is_valid_position(pos: Vector2i) -> bool:
	return not grid.has(pos)

# Helper function to get valid directions for a new connection
func get_valid_directions(from_pos: Vector2i) -> Array:
	var valid = []
	var directions = [
		Vector2i(0, -1),  # top (0)
		Vector2i(-1, 0),  # left (1)
		Vector2i(0, 1),   # bottom (2)
		Vector2i(1, 0)    # right (3)
	]
	
	for i in range(directions.size()):
		var new_pos = from_pos + directions[i]
		if is_valid_position(new_pos):
			valid.append(i)
	
	return valid
		
func generate_dungeon_graph():

	print_label('generate_dungeon_graph')

	# 1. Add the beginning room B.
	nodes.append({ "name": "B", "scene": ROOM_B, "world_grid" : Vector2i(0,0) })

	# 2. Add the enemy rooms E1 ... Eₙ.
	for i in range(1, n + 1):
		nodes.append({ "name": "E" + str(i), "scene": ROOM_E, "world_grid" : Vector2i(-1,-1) })

	# 3. Add the final room F.
	nodes.append({ "name": "F", "scene": ROOM_F, "world_grid" : Vector2i(-1,-1) })
	# In our backbone chain, F will automatically be connected to the last enemy (Eₙ).

	# 4. Add the shop room S.
	var shop_node = { "name": "S", "scene": ROOM_S, "world_grid" : Vector2i(-1,-1) }
	var shop_index = nodes.size()    # this will be its index
	nodes.append(shop_node)

	# 5. Add loot rooms L.
	# If m > 1, loot rooms are labeled L1, L2, etc.
	var loot_indices = []
	for j in range(1, m + 1):
		var loot_name = "L" if m == 1 else "L" + str(j)
		var loot_node = { "name": loot_name, "scene": ROOM_L, "world_grid" : Vector2i(-1,-1)}
		var loot_index = nodes.size()
		nodes.append(loot_node)
		loot_indices.append(loot_index)

	# --- Build the dungeon graph ---

	print_label('Building dungeon graph')

	# ... implement here

	
func print_label(text: String) -> void:
	debug_label.text = debug_label.text + text + "\n"

# func assign_room_world_grid():
# 	pass
