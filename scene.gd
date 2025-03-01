extends Control

func _ready() -> void:
	Main.register_control(self)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("dev_reload") and OS.is_debug_build():
		get_tree().reload_current_scene()
