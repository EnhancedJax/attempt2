extends Node2D

var floor: TileMapLayer
var room_list =  [Vector2i(5, 7), Vector2i(11, 7), Vector2i(9, 7), Vector2i(13, 11)]
var start_room = Vector2i(5, 5)
var end_room = Vector2i(5, 5)

func generate_dungeon() -> void:
	randomize()
	floor.clear()
	generate_dungeon_graph()

func set_tile(x: int, y: int) -> void:
	floor.set_cell(Vector2i(x, y), 0, Vector2i(0,0), 0)

func generate_dungeon_graph():
	# Parameters (you can change these as needed)
	var n:int = 3  # number of enemy rooms
	var m:int = 1  # number of loot rooms

	# Create an array to hold nodes.
	# Each node is represented as a dictionary with a room "name" and "type".
	# We will refer to nodes via their index in this array.
	var nodes = []

	# 1. Add the beginning room B.
	nodes.append({ "name": "B", "type": "B" })

	# 2. Add the enemy rooms E1 ... Eₙ.
	for i in range(1, n + 1):
		nodes.append({ "name": "E" + str(i), "type": "E" })

	# 3. Add the final room F.
	nodes.append({ "name": "F", "type": "F" })
	# In our backbone chain, F will automatically be connected to the last enemy (Eₙ).

	# 4. Add the shop room S.
	var shop_node = { "name": "S", "type": "S" }
	var shop_index = nodes.size()    # this will be its index
	nodes.append(shop_node)

	# 5. Add loot rooms L.
	# If m > 1, loot rooms are labeled L1, L2, etc.
	var loot_indices = []
	for j in range(1, m + 1):
		var loot_name = "L" if m == 1 else "L" + str(j)
		var loot_node = { "name": loot_name, "type": "L" }
		var loot_index = nodes.size()
		nodes.append(loot_node)
		loot_indices.append(loot_index)

	# --- Build the dungeon graph ---
	# We will store connections (edges) as Vector2 objects.
	# The two components (x and y) are the indices of the connected nodes.
	var edges = []

	# A. Create the backbone chain.
	# This chain is B --> E1 --> E2 --> ... --> Eₙ --> F.
	# Notice that B (index 0) and F (index n+1) now have only one edge.
	var backbone_end_count = n + 2   # B, n enemies, and F occupy the first n+2 nodes.
	for i in range(backbone_end_count - 1):
		edges.append(Vector2(i, i + 1))

	# B. Attach the shop.
	# Choose a random enemy from the backbone to attach S.
	# We avoid attaching to the last enemy (at index n) because F is already attached there.
	# Also, we avoid using B.
	var possible_enemy_indices = []
	for i in range(1, n):  # enemy nodes are at indices 1 .. n (but skip index n)
		possible_enemy_indices.append(i)
	if possible_enemy_indices.size() > 0:
		var shop_attach = possible_enemy_indices[randi() % possible_enemy_indices.size()]
		edges.append(Vector2(shop_attach, shop_index))
	else:
		# In case n is very small (though in a valid dungeon n>=3 is preferred)
		edges.append(Vector2(1, shop_index))

	# C. Attach each loot room as a branch.
	# For each loot room, attach it to a randomly chosen enemy on the backbone (again, not the last enemy).
	for loot_idx in loot_indices:
		var attach_index = possible_enemy_indices[randi() % possible_enemy_indices.size()]
		edges.append(Vector2(attach_index, loot_idx))

	# --- Print the results ---
	# Each edge (a Vector2) maps to two nodes by index.
	# We print the room names separated by a space.
	# (The order in the printed line does not matter, but the backbone creates the intended "B to F" order.)
	for edge in edges:
		var a = int(edge.x)
		var b = int(edge.y)
		print(nodes[a]["name"] + " " + nodes[b]["name"])