extends Node2D

var item : PackedScene = null
	# set(value):
	# 	if not value:
	# 		print('Floor item has no item. Removing.')
	# 		item = null
	# 		$Sprite2D.texture = null
	# 		return
		
	# 	item = value
	# 	var scene = value.instantiate()
	# 	for child in scene.get_children():
	# 		if child is Sprite2D:
	# 			$Sprite2D.texture = child.texture

var interaction : Interaction

func _ready() -> void:
	print(item)
	if item == null:
		print('Floor item has no item. Removing.')
		queue_free()
	interaction = Interaction.new()
	interaction.callable = interaction_action
	interaction.source = self
	interaction.label_position = $LabelPosition.global_position
	_update_item_metadata()
	
func interaction_action() -> void:
	var dropped_item = Main.player.pickup_weapon(item)
	if dropped_item:
		item = dropped_item
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
	if item:
		var scene: WeaponBase = item.instantiate()
		for child in scene.get_children():
			if child is Sprite2D:
				$Sprite2D.texture = child.texture
		
		interaction.label = scene.weapon_name
