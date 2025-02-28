class_name Room extends Resource

enum RoomType {
	ENEMY = 0,
	START = 1,
	END = 2,
	TREASURE = 3,
	SHOP = 4,
	BOSS = 9
}

@export var id: String
@export var dimension : Vector2
@export var entrances_tlbr : Array[Vector2]
@export var type : RoomType = RoomType.ENEMY
