extends Node

enum RoomType {
	ENTRANCE,
	ENEMY,
	LOOT,
	SHOP,
	BOSS,
	EXIT,
}

enum Direction {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
}

class Neighbours extends RefCounted:
	var top: int = -1
	var right: int = -1
	var bottom: int = -1
	var left: int = -1
	# indices of the rooms that are connected to this room

	func has_connection_to(direction: Direction) -> bool:
		match direction:
			Direction.TOP: return top != -1
			Direction.RIGHT: return right != -1
			Direction.BOTTOM: return bottom != -1
			Direction.LEFT: return left != -1
			_: return false

class Room extends RefCounted:
	var room_type: RoomType
	var neighbours: Neighbours
	var grid_position: Vector2i
	var id : int
	
	func _init():
		neighbours = Neighbours.new()
		grid_position = Vector2i(0, 0)
	
	func get_tlbr_neighbours() -> Array[int]:
		return [neighbours.top, neighbours.left, neighbours.bottom, neighbours.right]
	
	func get_neighbour_direction(neighbour: int) -> int:
		if neighbour == neighbours.top:
			return Direction.TOP
		elif neighbour == neighbours.left:
			return Direction.LEFT
		elif neighbour == neighbours.bottom:
			return Direction.BOTTOM
		elif neighbour == neighbours.right:
			return Direction.RIGHT
		return -1
	
	func get_neighbor_position(dir: Direction) -> Vector2i:
		match dir:
			Direction.TOP: return grid_position + Vector2i(0, -1)
			Direction.RIGHT: return grid_position + Vector2i(1, 0)
			Direction.BOTTOM: return grid_position + Vector2i(0, 1)
			Direction.LEFT: return grid_position + Vector2i(-1, 0)
			_: return grid_position


# Opposite direction mapping (for the reverse connection)
var opposite_direction = {
	Direction.TOP: Direction.BOTTOM,
	Direction.LEFT: Direction.RIGHT,
	Direction.BOTTOM: Direction.TOP,
	Direction.RIGHT: Direction.LEFT,
}

func get_door_value(scene_instance: Node, dir_code: Direction) -> Vector2:
	match dir_code:
		Direction.TOP:
			return scene_instance.entrances_top
		Direction.LEFT:
			return scene_instance.entrances_left
		Direction.BOTTOM:
			return scene_instance.entrances_bottom
		Direction.RIGHT:
			return scene_instance.entrances_right
		_:
			return Vector2.ZERO
