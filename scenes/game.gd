extends Control

@export var hud : HUD
@export var tile_layer : Node2D

func _ready() -> void:
	MusicManager.play("bgm", "bgm", 1.0, true)
	Main.show_title_ui('Level 0')
	Main.register_control(self)
	tile_layer.generate()

	_place_player_at_entrance()

func _place_player_at_entrance() -> void:
	var place_player_at = (Vector2(tile_layer.room_scenes[0].dimension) / 2) * 16 * tile_layer.global_scale
	Main.player.global_position = place_player_at
	Main.signal_player_room_changed.emit(tile_layer.room_scenes[0])

func rsignal_player_entered(room_index: int, scene: RoomBase) -> void:
	Main.hud.update_minimap(room_index)
	Main.handle_room_entered(scene)

func rsignal_room_cleared() -> void:
	Main.handle_room_cleared()
