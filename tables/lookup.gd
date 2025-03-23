extends Node

# Room type constants
enum RoomType { B, E, L, S, F }

const ALLY_WEAPONS_DATA_PATH = "res://tables/player_weapon_data.json"
const ENEMY_WEAPONS_DATA_PATH = "res://tables/enemy_weapon_data.json"
const ROOM_DATA_PATH = "res://tables/room_data.json"
var _ally_weapons: Dictionary = {}
var _enemy_weapons: Dictionary = {}
var _texture_cache: Dictionary = {}
var _level_room_scenes_list: LevelRoomScenesList

class WeaponType:
	var id: int
	var name: String
	var player_tooltip: String
	var scene: PackedScene
	var rarity: int
	var static_image: String # we only create texture when needed

class LevelRoomScenesList:
	var level1: RoomScenesList

class RoomScenesList:
	var B: Array[PackedScene] = []
	var S: Array[PackedScene] = []
	var E: Array[PackedScene] = []
	var F: Array[PackedScene] = []
	var L: Array[PackedScene] = []

func _ready() -> void:
	_load_ally_weapons()
	_load_enemy_weapons()
	_load_rooms()

func _load_ally_weapons() -> void:
	if FileAccess.file_exists(ALLY_WEAPONS_DATA_PATH):
		var file = FileAccess.open(ALLY_WEAPONS_DATA_PATH, FileAccess.READ)
		var json_object = JSON.parse_string(file.get_as_text())
		if json_object:
			for key in json_object:
				var weapon = json_object[key]
				var new_weapon = WeaponType.new()
				new_weapon.id = int(key)
				new_weapon.name = weapon.name
				var path_name = weapon.name.to_lower().replace(" ", "_")
				new_weapon.player_tooltip = weapon.desc
				var scene_path = "res://weapons/ally/%s/%s.tscn" % [path_name, path_name]
				print(scene_path)
				new_weapon.scene = load(scene_path)
				new_weapon.rarity = weapon.rarity
				new_weapon.static_image = "res://weapons/ally/%s/static.png" % [path_name]
				_ally_weapons[int(key)] = new_weapon

func _load_enemy_weapons() -> void:
	if FileAccess.file_exists(ENEMY_WEAPONS_DATA_PATH):
		var file = FileAccess.open(ENEMY_WEAPONS_DATA_PATH, FileAccess.READ)
		var json_object = JSON.parse_string(file.get_as_text())
		if json_object:
			for key in json_object:
				var weapon = json_object[key]
				var new_weapon = WeaponType.new()
				new_weapon.id = int(key)
				new_weapon.name = weapon.name
				var scene_path = "res://weapons/enemy/%s/%s.tscn" % [weapon.name.to_lower().replace(" ", "_"), weapon.name.to_lower().replace(" ", "_")]
				print(scene_path)
				new_weapon.scene = load(scene_path)
				_enemy_weapons[int(key)] = new_weapon

func _load_rooms():
	if not FileAccess.file_exists(ROOM_DATA_PATH):
		push_error("Room data file not found")
		return
		
	var file = FileAccess.open(ROOM_DATA_PATH, FileAccess.READ)
	var json_object = JSON.parse_string(file.get_as_text())
	if not json_object:
		push_error("Failed to parse room data JSON")
		return
		
	var level_rooms = LevelRoomScenesList.new()
	var level1 = RoomScenesList.new()
	
	var level_data = json_object["1"]  # Level 1 data
	for room_type in level_data:
		var scenes: Array[PackedScene]
		match room_type:
			"B": scenes = level1.B
			"E": scenes = level1.E
			"L": scenes = level1.L
			"S": scenes = level1.S
			"F": scenes = level1.F
			
		for room_name in level_data[room_type]:
			var path = "res://scenes/rooms/level1/%s.tscn" % room_name
			var scene = load(path)
			print('loaded %s' % path)
			scenes.append(scene)
	
	level_rooms.level1 = level1
	_level_room_scenes_list = level_rooms

func get_droppable_items() -> Array[Variant]:
	return _ally_weapons.keys()

func get_weapon(id: int, is_ally: bool = true) -> WeaponType:
	var weapons_dict = _ally_weapons if is_ally else _enemy_weapons
	if weapons_dict.has(id):
		return weapons_dict[id]
	push_error("Weapon with id %d not found" % id)
	return null

func get_weapon_texture(id: int, _weapon: WeaponType = null, is_ally: bool = true) -> CompressedTexture2D:
	var weapon = _weapon
	if not weapon:
		weapon = get_weapon(id, is_ally)
	if weapon:
		if weapon.static_image in _texture_cache:
			return _texture_cache[weapon.static_image]
		var texture = ResourceLoader.load(weapon.static_image)
		_texture_cache[weapon.static_image] = texture
		return texture
	return null

func clear_texture_cache() -> void:
	_texture_cache.clear()

func get_room_list(room_type: int) -> Array[PackedScene]:
	match room_type:
		RoomType.B:
			return _level_room_scenes_list.level1.B
		RoomType.S:
			return _level_room_scenes_list.level1.S
		RoomType.F:
			return _level_room_scenes_list.level1.F
		RoomType.L:
			return _level_room_scenes_list.level1.L
		RoomType.E:
			return _level_room_scenes_list.level1.E
	return []
