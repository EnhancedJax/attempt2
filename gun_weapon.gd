extends Node2D

const BULLET = preload('res://bullet.tscn')
@onready var bullet_spawn: Marker2D = $BulletSpawn
@export var fire_rate : int = 5 # bullets per second
var can_fire : bool = true
var fire_timer : float = (1.0 / fire_rate)
var spread_variation : int = 5 # angle in degrees

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func shoot():
	if not $RayCast2D.is_colliding():
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = bullet_spawn.global_position
		var random_spread = randf_range(-spread_variation, spread_variation)
		bullet_instance.rotation = rotation + deg_to_rad(random_spread)
		$"../Camera2D".apply_shake(5)
		

func _process(delta):
	# Get the global mouse position
	look_at(get_global_mouse_position())
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		$SpriteWrapper/GunSprite.scale.y = -1
	else:
		$SpriteWrapper/GunSprite.scale.y = 1
		
	if not can_fire:
		fire_timer += delta
		if fire_timer > (1.0 / fire_rate):
			can_fire = true
	
	if Input.is_action_pressed("fire"):
		fire_timer += delta
		if fire_timer > (1.0 / fire_rate):
			shoot()
			fire_timer = 0
	
	if Input.is_action_just_released("fire"):
		can_fire = false
		fire_timer = 0
