extends RoomBase

func _ready() -> void:
	super._ready()
	spawn_items()

func spawn_items() -> void:
	var room_center = _get_room_center()
	var item_gap = tilemap_px * 3

	# Spawn heart
	var is_full_heart = randi() % 2 == 0
	var heart_position = room_center - Vector2(item_gap, 0)
	PickupManager.spawn_heart(heart_position, is_full_heart, true)

	# Get random weapons
	var weapons = Lookup.get_droppable_items()
	weapons.shuffle()
	var weapon1 = weapons.pop_front()
	var weapon2 = weapons.pop_front()

	# Spawn weapons
	var weapon1_position = room_center
	var weapon2_position = room_center + Vector2(item_gap, 0)
	PickupManager.spawn_weapon(weapon1_position, weapon1, true)
	PickupManager.spawn_weapon(weapon2_position, weapon2, true)
