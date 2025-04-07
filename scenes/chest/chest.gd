extends InteractionSource

var items
@export var spawned_in_active_room : bool = false
@export var items_count : int
var is_opened : bool = false
const item_spacing : int = 32
  # pixels between items
const coin_scene = preload("res://scenes/coin/coin_spawner.tscn")

var parent_room : RoomBase
var _is_player_in_parent_room : bool = false

func _ready() -> void:
	randomize()
	items = Lookup.get_droppable_items()
	i = Interaction.new()
	i.callable = interaction_action
	i.source = self
	i.label_position = $LabelPosition.global_position
	i.label = "Open chest"
	var parent = self.get_parent()
	if parent is RoomBase:
		parent_room = parent
	
	Main.signal_player_entered_room.connect(_on_player_entered_room)
	if spawned_in_active_room:
		_on_player_entered_room(parent_room)
	
func interaction_action(_ref: InteractionSource, _params: Array[int]) -> void:
	SoundManager.play('chest', 'open')
	var shuffled_items = items.duplicate()
	for weapon in Main.player.weapons:
		shuffled_items.erase(weapon)
	shuffled_items.shuffle()
	var total_width = int((items_count - 1) * item_spacing)
	var start_x = int(-total_width / 2.0)  # center offset
	
	for idx in range(items_count):
		var random_item = shuffled_items[idx]
		
		var spawn_position = $ItemSpawnPosition.global_position
		spawn_position.x += start_x + (idx * item_spacing)
		PickupManager.spawn_weapon(spawn_position, random_item)
		
	var coin = coin_scene.instantiate()
	coin.count = 5
	Main.spawn_node(coin, global_position, 3)
	
	is_opened = true
	$AnimatedSprite2D.play("open")
	$AnimationPlayer.play("open")
	Main.deregister_interaction(i)

func _on_player_entered() -> void:
	if is_opened:
		return
	Main.register_interaction(i)

func _on_player_exited() -> void:
	if is_opened:
		return
	Main.deregister_interaction(i)

func _on_player_entered_room(room: RoomBase) -> void:
	if room == parent_room:
		if not _is_player_in_parent_room:
			$AnimationPlayer.play("enter")
		_is_player_in_parent_room = true
	else:
		if _is_player_in_parent_room:
			$AnimationPlayer.play_backwards("enter")
		_is_player_in_parent_room = false
