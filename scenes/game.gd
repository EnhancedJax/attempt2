extends Control

@export var hud : HUD

func _ready() -> void:
	Main.show_title_ui('Level 0')
	MusicManager.loaded.connect(on_music_manager_loaded)
	Main.register_control(self)
	var result_dict = $TileLayer.generate_new_dungeon()
	Main.hud.draw_minimap(result_dict.nodes)
	var place_player_at = (Vector2(result_dict.room_scenes[0].dimension) / 2) * 16 * $TileLayer.global_scale
	Main.player.global_position = place_player_at
	for i in result_dict.room_scenes.size():
		var scene = result_dict.room_scenes[i]
	
		scene.signal_player_entered.connect(rsignal_player_entered.bind(i, scene))
		scene.signal_room_cleared.connect(rsignal_room_cleared)

func on_music_manager_loaded() -> void:
	MusicManager.play("bgm", "bgm", 5.0, true)

func rsignal_player_entered(room_index: int, scene: RoomBase) -> void:
	Main.hud.update_minimap(room_index)
	Main.handle_room_entered(scene)

func rsignal_room_cleared() -> void:
	Main.handle_room_cleared()
