extends Node2D

var item_id : int = -1

var interaction : Interaction

func _ready() -> void:
	if item_id == null:
		print('Floor item_id is -1. Removing.')
		queue_free()
	interaction = Interaction.new()
	interaction.callable = interaction_action
	interaction.source = self
	interaction.label_position = $LabelPosition.global_position
	_update_item_metadata()
	
func interaction_action() -> void:
	var dropped_item = Main.player.pickup_weapon(item_id)
	if dropped_item != -1:
		item_id = dropped_item
		_update_item_metadata()
		Main.reregister_interaction(interaction)
	else:
		Main.deregister_interaction(interaction)
		queue_free()

func rsignal_player_entered() -> void:
	Main.register_interaction(interaction)

func rsignal_player_exited() -> void:
	Main.deregister_interaction(interaction)

func _update_item_metadata() -> void:
	if item_id != -1:
		var weapon = Lookup.get_weapon(item_id)
		$Sprite2D.texture = Lookup.get_weapon_texture(-1, weapon)
		
		interaction.label = weapon.name
