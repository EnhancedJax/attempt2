extends Button

@export var route : String

func _on_pressed() -> void:
	Router.navigate(route)
