extends CanvasLayer

func _on_resume_button_pressed() -> void:
	Router.go_back()


func _on_settings_button_pressed() -> void:
	Router.navigate('settings')


func _on_quit_button_pressed() -> void:
	Input.action_press('dev_reload')
	Input.action_release('dev_reload')
