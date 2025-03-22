extends Control

@export var action : String

var _touch_index : int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_button_area(event.position) and _touch_index == -1:
				_touch_index = event.index
				_on_button_pressed()
				get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_touch_index = -1
			_on_button_released()
			get_viewport().set_input_as_handled()

func _is_point_inside_button_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func _on_button_pressed() -> void:
	# # Change the color of the button to indicate it is pressed
	# $TextureRect.modulate = Color(1, 1, 1, 0.5)
	# Emit a signal or call a function to handle the button press
	print("Button pressed: ", action)
	Input.action_press(action)

func _on_button_released() -> void:
	# # Reset the color of the button to its original state
	# $TextureRect.modulate = Color(1, 1, 1, 0.2)
	# Emit a signal or call a function to handle the button release
	print("Button released: ", action)
	if Input.is_action_pressed(action):
		Input.action_release(action)
