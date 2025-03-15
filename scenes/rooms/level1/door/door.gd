class_name Door
extends StaticBody2D
var is_opened = false
var is_locked = false

@export var door1 : AnimatedSprite2D
@export var door2 : AnimatedSprite2D
@export var is_horizontal : bool

func _ready() -> void:
	if is_horizontal:
		door1.frame = door1.sprite_frames.get_frame_count("bottom") -1
		door2.frame = door1.sprite_frames.get_frame_count("bottom") -1

func call_open_door() -> void:
	_handle_open_door(0)

func call_close_door() -> void:
	_handle_close_door()

func call_lock_door() -> void:
	is_locked = true
	
func call_unlock_door() -> void:
	is_locked = false

func _handle_open_door(bottom: bool) -> void:
	var anim = 'bottom' if bottom else 'top'
	is_opened = true
	if is_horizontal:
		var flip : int = -1 if bottom else 1
		door1.play_backwards('top')
		door2.play_backwards('bottom')
		door1.scale.x = flip
		door2.scale.x = flip
	else:
		door1.play(anim)
		door2.play(anim)
	set_collision(false)

func _handle_close_door() -> void:
	if is_opened:
		set_collision(true)
		door1.stop()
		door2.stop()
		if is_horizontal:
			door1.play()
			door2.play()
		else:
			door1.play_backwards()
			door2.play_backwards()

func set_collision(b: bool) -> void:
	self.set_collision_layer_value(1,b)
	self.set_collision_layer_value(1,b)

func rsignal_player_entered_top(body: Node2D) -> void:
	if not is_opened and not is_locked:
		_handle_open_door(false)

func rsignal_player_entered_bottom(body: Node2D) -> void:
	if not is_opened and not is_locked:
		_handle_open_door(true)
