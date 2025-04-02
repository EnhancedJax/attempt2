extends Control

# Add static variable to track active button per finger index.
static var active_buttons: Dictionary = {}
var _slid_just_now: bool = false

@export var action: String
@export var slide_group: String

var _touch_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_button_area(event.position) and _touch_index == -1 and not active_buttons.has(event.index):
				_touch_index = event.index
				active_buttons[event.index] = self
				print("[OnscreenControl] Button pressed (original): ", action)
				_on_button_pressed()
				get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_touch_index = -1
			print("[OnscreenControl] Button released (original): ", action)
			_on_button_released()
			active_buttons.erase(event.index)
			_slid_just_now = false
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		# If this button is not the original for the finger and shares the same slide_group.
		if active_buttons.has(event.index) and active_buttons[event.index] != self and slide_group == active_buttons[event.index].slide_group:
			if _is_point_inside_button_area(event.position):
				if not _slid_just_now:
					print("[OnscreenControl] Sliding press on: ", action)
					Input.action_press(action)
					print("[OnscreenControl] Sliding release on: ", action)
					Input.action_release(action)
					_slid_just_now = true
			else:
				_slid_just_now = false

func _is_point_inside_button_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func _on_button_pressed() -> void:
	print("[OnscreenControl] Action press: ", action)
	Input.action_press(action)

func _on_button_released() -> void:
	print("[OnscreenControl] Action release: ", action)
	if Input.is_action_pressed(action):
		Input.action_release(action)
