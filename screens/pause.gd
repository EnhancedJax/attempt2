extends CanvasLayer

func _on_resume_button_pressed() -> void:
	Router.go_back()


func _on_settings_button_pressed() -> void:
	Router.navigate('settings')


func _on_quit_button_pressed() -> void:
	Router.go_back()
	Input.action_press('dev_reload')
