extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var zoom_speed = 3 * delta
	var move_speed = 2000 * delta / zoom.x
	
	if Input.is_key_label_pressed(KEY_A):
		position.x -= move_speed
	if Input.is_key_label_pressed(KEY_D):
		position.x += move_speed
	if Input.is_key_label_pressed(KEY_W):
		position.y -= move_speed
	if Input.is_key_label_pressed(KEY_S):
		position.y += move_speed
	if Input.is_key_label_pressed(KEY_Q):
		zoom.x += zoom_speed
		zoom.y += zoom_speed
	if Input.is_key_label_pressed(KEY_E):
		zoom.x -= zoom_speed
		zoom.y -= zoom_speed
