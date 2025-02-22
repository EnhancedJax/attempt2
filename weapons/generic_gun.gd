extends Node2D
class_name GenericGun

const BULLET = preload('res://weapons/bullet.tscn')
@export var fire_rate: int = 5 # bullets per second
@export var damage: int = 1
@export var spread_variation: int = 5 # angle in degrees
@export var auto_fire: bool = false

var can_fire: bool = true
var fire_timer: float = 0

func _process(delta: float) -> void:
	handle_firing(delta)
	update_aim()

func handle_firing(delta: float) -> void:
	if not can_fire:
		fire_timer += delta
		if fire_timer > (1.0 / fire_rate):
			can_fire = true

	if auto_fire:
		handle_auto_fire(delta)
	else:
		handle_manual_fire(delta)

func handle_auto_fire(delta: float) -> void:
	fire_timer += delta
	if fire_timer > (1.0 / fire_rate):
		shoot()
		fire_timer = 0

func handle_manual_fire(delta: float) -> void:
	if Input.is_action_pressed("fire"):
		if can_fire:
			shoot()
			can_fire = false
			fire_timer = 0

func shoot() -> void:
	var bullet_instance = BULLET.instantiate()
	get_tree().root.add_child(bullet_instance)
	configure_bullet(bullet_instance)
	#$RandomizedAudio.play()

func configure_bullet(bullet: Node2D) -> void:
	bullet.global_position = get_bullet_spawn_position()
	bullet.owner_node = get_parent()
	var random_spread = randf_range(-spread_variation, spread_variation)
	bullet.rotation = rotation + deg_to_rad(random_spread)
	bullet.hit_points = damage

func update_aim() -> void:
	var gun_user = get_parent()
	if gun_user.has_method("get_aim_position"):
		look_at(gun_user.get_aim_position())

func get_bullet_spawn_position() -> Vector2:
	return global_position
