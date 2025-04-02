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

class Room extends RefCounted:
	var room_type: RoomType
	var neighbours: Neighbours
	var connected_rooms: Array[int]
	
	func _init():
		neighbours = Neighbours.new()
		connected_rooms = []
	
	func get_tlbr_neighbours() -> Array[int]:
		return [neighbours.top, neighbours.left, neighbours.bottom, neighbours.right]
	
	func get_neighbour_direction(neighbour: int) -> int:
		if neighbour == neighbours.top:
			return DIR_TOP
		elif neighbour == neighbours.left:
			return DIR_LEFT
		elif neighbour == neighbours.bottom:
			return DIR_BOTTOM
		elif neighbour == neighbours.right:
			return DIR_RIGHT
		return -1


const DIR_TOP = 1  
const DIR_LEFT = 2  
const DIR_BOTTOM = 3
const DIR_RIGHT = 4 

# Opposite direction mapping (for the reverse connection)
var opposite_direction = {
	DIR_TOP: DIR_BOTTOM,
	DIR_LEFT: DIR_RIGHT,
	DIR_BOTTOM: DIR_TOP,
	DIR_RIGHT: DIR_LEFT,
}

func get_door_value(scene_instance: Node, dir_code: int) -> Vector2:
	match dir_code:
		Dungen.DIR_TOP:
			return scene_instance.entrances_top
		Dungen.DIR_LEFT:
			return scene_instance.entrances_left
		Dungen.DIR_BOTTOM:
			return scene_instance.entrances_bottom
		Dungen.DIR_RIGHT:
			return scene_instance.entrances_right
		_:
			return Vector2.ZERO
