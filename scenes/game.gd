extends Control

func _ready() -> void:
	Main.register_control(self)
	var result_dict = $TileLayer.generate_new_dungeon()
	Main.hud.draw_minimap(result_dict['nodes'])
	for i in result_dict['room_scenes'].size():
		var scene = result_dict['room_scenes'][i]
		scene.signal_player_entered.connect(rsignal_player_entered.bind(i))
		scene.signal_room_cleared.connect(rsignal_room_cleared)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("dev_reload") and OS.is_debug_build():
		get_tree().reload_current_scene()

func rsignal_player_entered(room_id: int) -> void:
	Main.hud.update_minimap(room_id)

func rsignal_room_cleared() -> void:
	Main.show_title_ui("Clear!")
