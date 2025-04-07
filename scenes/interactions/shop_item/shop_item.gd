extends InteractionSource

@export var item_sprite: Sprite2D

var item_id : int = 0

func _ready() -> void:
	Main.signal_interaction_changed.connect(handle_interaction_changed)
	if item_id == null:
		print('Floor item_id is -1. Removing.')
		queue_free()
	i = Interaction.new()
	i.callable = interaction_action
	i.source = self
	i.label_position = $LabelPosition.global_position
	_update_item_metadata()
	
func handle_interaction_changed(_i: Interaction) -> void:
	if _i != i:
		item_sprite.material.set_shader_parameter("width", 0)

func interaction_action(_ref: InteractionSource, _params: Array[int]) -> void:
	var dropped_item = Main.player.pickup_weapon(item_id)
	if dropped_item != -1:
		item_id = dropped_item
		_update_item_metadata()
		Main.reregister_interaction(i)
	else:
		Main.deregister_interaction(i)
		queue_free()

func _on_player_entered() -> void:
	Main.register_interaction(i)
	item_sprite.material.set_shader_parameter("width", 1)

func _on_player_exited() -> void:
	Main.deregister_interaction(i)
	item_sprite.material.set_shader_parameter("width", 0)

func _update_item_metadata() -> void:
	if item_id != -1:
		var weapon = Lookup.get_weapon(item_id)
		item_sprite.texture = Lookup.get_weapon_texture(-1, weapon)
		
		i.label = weapon.name
