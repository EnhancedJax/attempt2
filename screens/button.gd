extends Button


func _on_pressed() -> void:
	print('pressed')
	Router.navigate("/game")
