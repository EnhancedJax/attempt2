extends Control

@export var hud : HUD
@export var tile_layer : Node2D

func _ready() -> void:
	MusicManager.play("bgm", "bgm", 1.0, true)
	Main.show_title_ui('Level 0')
	Main.register_control(self)
	tile_layer.generate()
	var rooms = tile_layer.rooms
	var room_scenes = tile_layer.room_scenes

	# Main.hud.draw_minimap(rooms)

	# _place_player_at_entrance()
	# _register_all_rooms()

func _place_player_at_entrance() -> void:
	var place_player_at = (Vector2(tile_layer.room_scenes[0].dimension) / 2) * 16 * tile_layer.global_scale
	Main.player.global_position = place_player_at

func _register_all_rooms() -> void:
	_clear_all_signals()
	for i in tile_layer.room_scenes.size():
		var scene = tile_layer.room_scenes[i]
	
		scene.signal_player_entered.connect(rsignal_player_entered.bind(i, scene))
		scene.signal_room_cleared.connect(rsignal_room_cleared)

func _clear_all_signals() -> void:
	var signals = self.get_incoming_connections()
	for s in signals:
		var _signal : Signal = s.signal
		var _callable : Callable = s.callable
		_signal.disconnect(_callable)

func rsignal_player_entered(room_index: int, scene: RoomBase) -> void:
	Main.hud.update_minimap(room_index)
	Main.handle_room_entered(scene)

func rsignal_room_cleared() -> void:
	Main.handle_room_cleared()
