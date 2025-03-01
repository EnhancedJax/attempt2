extends Node

const PROTAGONIST_WEAPONS_DATA_PATH = "res://tables/player_weapon_data.json"
const ANTAGONIST_WEAPONS_DATA_PATH = "res://tables/enemy_weapon_data.json"
var _protagonist_weapons: Dictionary = {}
var _antagonist_weapons: Dictionary = {}

class WeaponType:
	var id: int
	var name: String
	var player_tooltip: String
	var scene: PackedScene
	var rarity: int

func _ready() -> void:
	load_protagonist_weapons()
	load_antagonist_weapons()

func load_protagonist_weapons() -> void:
	if FileAccess.file_exists(PROTAGONIST_WEAPONS_DATA_PATH):
		var file = FileAccess.open(PROTAGONIST_WEAPONS_DATA_PATH, FileAccess.READ)
		var json_object = JSON.parse_string(file.get_as_text())
		if json_object:
			for key in json_object:
				var weapon = json_object[key]
				var new_weapon = WeaponType.new()
				new_weapon.id = int(key)
				new_weapon.name = weapon.name
				new_weapon.player_tooltip = weapon.desc
				var scene_path = "res://weapons/protagonists/%s/%s.tscn" % [weapon.name.to_lower().replace(" ", "_"), weapon.name.to_lower().replace(" ", "_")]
				print(scene_path)
				new_weapon.scene = load(scene_path)
				new_weapon.rarity = weapon.rarity
				_protagonist_weapons[int(key)] = new_weapon

func load_antagonist_weapons() -> void:
	if FileAccess.file_exists(ANTAGONIST_WEAPONS_DATA_PATH):
		var file = FileAccess.open(ANTAGONIST_WEAPONS_DATA_PATH, FileAccess.READ)
		var json_object = JSON.parse_string(file.get_as_text())
		if json_object:
			for key in json_object:
				var weapon = json_object[key]
				var new_weapon = WeaponType.new()
				new_weapon.id = int(key)
				new_weapon.name = weapon.name
				var scene_path = "res://weapons/antagonists/%s/%s.tscn" % [weapon.name.to_lower().replace(" ", "_"), weapon.name.to_lower().replace(" ", "_")]
				print(scene_path)
				new_weapon.scene = load(scene_path)
				_antagonist_weapons[int(key)] = new_weapon


func get_weapon(id: int, is_protagonist: bool = true) -> WeaponType:
	var weapons_dict = _protagonist_weapons if is_protagonist else _antagonist_weapons
	if weapons_dict.has(id):
		return weapons_dict[id]
	push_error("Weapon with id %d not found" % id)
	return null

func get_weapon_texture(id: int, _weapon: WeaponType = null, is_protagonist: bool = true) -> Texture:
	var weapon = _weapon
	if not weapon:
		weapon = get_weapon(id, is_protagonist)
	if weapon:
		var scene = weapon.scene.instantiate()
		var texture = scene.get_node("Sprite2D").texture
		scene.queue_free()
		return texture
	return null
