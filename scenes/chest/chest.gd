extends Node2D

var items : Array[int]
var items_count : int
var is_opened : bool = false
const floor_item = preload("res://scenes/floor_item/floor_item.tscn")

var interaction : Interaction

func _ready() -> void:
	items = [0,1,2]
	items_count = 1
	interaction = Interaction.new()
	interaction.callable = interaction_action
	interaction.source = self
	interaction.label_position = $LabelPosition.global_position
	interaction.label = "Open chest"
	
func interaction_action() -> void:
	var shuffled_items = items.duplicate()
	print(items_count)
	shuffled_items.shuffle()
	var item_spacing = 100  # pixels between items
	var total_width = (items_count - 1) * item_spacing
	var start_x = -total_width / 2  # center offset
	
	for i in range(items_count):
		var node = floor_item.instantiate()
		var random_item = shuffled_items[i]
		node.item_id = random_item
		
		var spawn_position = $ItemSpawnPosition.global_position
		spawn_position.x += start_x + (i * item_spacing)
		Main.spawn_node(node, spawn_position, 1)
	
	is_opened = true
	$AnimatedSprite2D.play("open")
	Main.deregister_interaction(interaction)

func rsignal_player_entered() -> void:
	if is_opened:
		return
	Main.register_interaction(interaction)

func rsignal_player_exited() -> void:
	if is_opened:
		return
	Main.deregister_interaction(interaction)
