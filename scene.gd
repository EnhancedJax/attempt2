extends Control

func _ready() -> void:
	Main.register_control(self)
	var room_nodes = $TileLayer.generate_new_dungeon()
	$Viewport/HUD.load_minimap(room_nodes)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("dev_reload") and OS.is_debug_build():
		get_tree().reload_current_scene()
