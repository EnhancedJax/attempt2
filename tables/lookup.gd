extends Node

const ALLY_WEAPONS_DATA_PATH = "res://tables/player_weapon_data.json"
const ENEMY_WEAPONS_DATA_PATH = "res://tables/enemy_weapon_data.json"
var _ally_weapons: Dictionary = {}
var _enemy_weapons: Dictionary = {}
var _texture_cache: Dictionary = {}

class WeaponType:
	var id: int
	var name: String
	var player_tooltip: String
	var scene: PackedScene
	var rarity: int
	var static_image: String # we only create texture when needed

func _ready() -> void:
	load_ally_weapons()
	load_enemy_weapons()

func load_ally_weapons() -> void:
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

func load_enemy_weapons() -> void:
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


func get_weapon(id: int, is_ally: bool = true) -> WeaponType:
	var weapons_dict = _ally_weapons if is_ally else _enemy_weapons
	if weapons_dict.has(id):
		return weapons_dict[id]
	push_error("Weapon with id %d not found" % id)
	return null

func get_weapon_texture(id: int, _weapon: WeaponType = null, is_ally: bool = true) -> ImageTexture:
	var weapon = _weapon
	if not weapon:
		weapon = get_weapon(id, is_ally)
	if weapon:
		if weapon.static_image in _texture_cache:
			return _texture_cache[weapon.static_image]
		var image = Image.load_from_file(weapon.static_image)
		var texture = ImageTexture.create_from_image(image)
		_texture_cache[weapon.static_image] = texture
		return texture
	return null

func clear_texture_cache() -> void:
	_texture_cache.clear()
