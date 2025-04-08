extends Node

const floor_item = preload("res://scenes/interactions/floor_item/floor_item.tscn")
const heart_full = preload("res://tables/pickups/heart/heart.png")
const heart_half = preload("res://tables/pickups/heart/heart_half.png")

# All actions should have first parameter as InteractionSource, and params as Array[int]
# InteractionSource will store the passed array of parameters. If an interaction needs to be registered, you can update the InteractionSource's parameters, and call 
#region Heart pickup

func spawn_heart(global_position: Vector2, is_full_heart: bool = true, have_price: bool = false) -> void:
	var price = -1
	var heart_texture = heart_full
	var heart_label = "Heart"
	if not is_full_heart:
		heart_texture = heart_half
		heart_label = "Half a heart"
	if have_price:
		price = Lookup.get_pickups_cost(Lookup.PICKUPS.HEART)
	_spawn_pickup(_action_pickup_heart, [is_full_heart], global_position, heart_label, heart_texture, price)

func _action_pickup_heart(ref: InteractionSource, params: Array[int]) -> void:
	var is_full_heart = params[0]
	Main.player.pickup_heart(is_full_heart)
	Main.deregister_interaction(ref.i)
	ref.queue_free()

#region Weapon pickup

func spawn_weapon(global_position: Vector2, weapon_id: int = -1, have_price: bool = false) -> void:
	var price = -1
	if weapon_id == -1:
		var weapons = Lookup.get_droppable_items()
		weapon_id = weapons[randi() % weapons.size()]
	if have_price:
		price = Lookup.get_item_cost(weapon_id)
	
	var l = Lookup.get_weapon(weapon_id).name
	var t = Lookup.get_weapon_texture(weapon_id)
	_spawn_pickup(_action_pickup_weapon, [weapon_id], global_position, l, t, price)

func _action_pickup_weapon(ref: InteractionSource, params: Array[int]) -> void:
	var weapon_id = params[0]
	var dropped_weapon_id = Main.player.pickup_weapon(weapon_id)
	if dropped_weapon_id != -1:
		ref.i_params = [dropped_weapon_id]
		ref.update_item_meta(Lookup.get_weapon(dropped_weapon_id).name, Lookup.get_weapon_texture(dropped_weapon_id))
		ref.i.price = -1
		Main.reregister_interaction(ref.i)
	else:
		Main.deregister_interaction(ref.i)
		ref.queue_free()

#region Internals

func _spawn_pickup(callable: Callable, params : Array[int], _pos: Vector2, label: String, texture: Texture2D, price: int) -> void:
	var ref = floor_item.instantiate()
	Main.spawn_node(ref, _pos, 3)
	ref.register(callable, params, price) # register after adding to tree for label position to update.
	ref.update_item_meta(label, texture)
