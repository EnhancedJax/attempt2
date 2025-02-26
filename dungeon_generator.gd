extends Node2D

var floor: TileMapLayer
var room_list =  [Vector2i(5, 7), Vector2i(11, 7), Vector2i(9, 7), Vector2i(13, 11)]
var start_room = Vector2i(5, 5)
var end_room = Vector2i(5, 5)

func generate_dungeon() -> void:
	floor.clear()
	RectangleShape2D.new()

func set_tile(x: int, y: int) -> void:
	floor.set_cell(Vector2i(x, y), 0, Vector2i(0,0), 0)