extends Node2D

var items
@export var items_count : int
var is_opened : bool = false
const item_spacing : int = 32
  # pixels between items
const floor_item = preload("res://scenes/floor_item/floor_item.tscn")
const coin_scene = preload("res://scenes/coin/coin_spawner.tscn")

var interaction : Interaction
var parent_room : RoomBase
var _is_player_in_parent_room : bool = false

func _ready() -> void:
	randomize()
	items = Lookup.get_droppable_items()
	interaction = Interaction.new()
	interaction.callable = interaction_action
	interaction.source = self
	interaction.label_position = $LabelPosition.global_position
	interaction.label = "Open chest"
	var parent = self.get_parent()
	if parent is RoomBase:
		parent_room = parent
	
	Main.signal_player_entered_room.connect(rsignal_player_entered_room)
	
func interaction_action() -> void:
	var shuffled_items = items.duplicate()
	for i in Main.player.weapons:
		shuffled_items.erase(i)
	shuffled_items.shuffle()
	var total_width = (items_count - 1) * item_spacing
	var start_x = -total_width / 2  # center offset
	
	for i in range(items_count):
		var node = floor_item.instantiate()
		var random_item = shuffled_items[i]
		node.item_id = random_item
		
		var spawn_position = $ItemSpawnPosition.global_position
		spawn_position.x += start_x + (i * item_spacing)
		Main.spawn_node(node, spawn_position, 3)
		
	var coin = coin_scene.instantiate()
	coin.count = 5
	Main.spawn_node(coin, global_position, 3)
	
	is_opened = true
	$AnimatedSprite2D.play("open")
	$AnimationPlayer.play("open")
	Main.deregister_interaction(interaction)

func rsignal_player_entered() -> void:
	if is_opened:
		return
	Main.register_interaction(interaction)

func rsignal_player_exited() -> void:
	if is_opened:
		return
	Main.deregister_interaction(interaction)

func rsignal_player_entered_room(room: RoomBase) -> void:
	if room == parent_room:
		if not _is_player_in_parent_room:
			$AnimationPlayer.play("enter")
		_is_player_in_parent_room = true
	else:
		if _is_player_in_parent_room:
			$AnimationPlayer.play_backwards("enter")
		_is_player_in_parent_room = false
