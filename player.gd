extends CharacterBody2D

var speed : int = 1200
var screen_size : Vector2
var max_health : int = 5
var health : int = max_health
var shield_on : bool = true

func _ready():
	#screen_size = get_viewport_rect().size
	#position = screen_size / 2
	$AnimatedSprite2D.play()
	$"../CanvasLayer/HUD".update_health(health, max_health)

func get_input():
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * speed

func _physics_process(_delta):
	get_input()
	move_and_slide()
	check_mouse_position()
	
	if velocity.length() != 0:
		$AnimatedSprite2D.play('walk')
	else:
		$AnimatedSprite2D.play('default')

func check_mouse_position():
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
