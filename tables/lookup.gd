extends Node

const WEAPONS_DATA_PATH = "res://tables/player_weapon_data.json"
var _weapons: Dictionary = {}

class WeaponType:
	var id: int
	var name: String
	var player_tooltip: String
	var scene: PackedScene
	var rarity: int

func _ready() -> void:
	load_weapons()

func load_weapons() -> void:
	if FileAccess.file_exists(WEAPONS_DATA_PATH):
		var file = FileAccess.open(WEAPONS_DATA_PATH, FileAccess.READ)
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
				_weapons[int(key)] = new_weapon

func get_weapon(id: int) -> WeaponType:
	if _weapons.has(id):
		return _weapons[id]
	push_error("Weapon with id %d not found" % id)
	return null
