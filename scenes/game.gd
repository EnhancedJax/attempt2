extends Control

@export var hud : HUD

func _ready() -> void:
	MusicManager.play("bgm", "bgm", 1.0, true)
	Main.show_title_ui('Level 0')
	Main.register_control(self)
	$TileLayer.generate()
	var rooms = $TileLayer.rooms
	var room_scenes = $TileLayer.room_scenes

	Main.hud.draw_minimap(rooms)
	var place_player_at = (Vector2(room_scenes[0].dimension) / 2) * 16 * $TileLayer.global_scale
	Main.player.global_position = place_player_at
	for i in room_scenes.size():
		var scene = room_scenes[i]
	
		scene.signal_player_entered.connect(rsignal_player_entered.bind(i, scene))
		scene.signal_room_cleared.connect(rsignal_room_cleared)

func rsignal_player_entered(room_index: int, scene: RoomBase) -> void:
	Main.hud.update_minimap(room_index)
	Main.handle_room_entered(scene)

func rsignal_room_cleared() -> void:
	Main.handle_room_cleared()
