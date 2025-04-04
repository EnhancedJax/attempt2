class_name GolemLaserState
extends State

@export var attack_anim_player : AnimationPlayer
@export var laser : LaserBulletProps
@export var laser_spawn_point : Marker2D
@export_range(0, 360) var rotation_angle_degrees : float = 180.0  # Rotation angle in degrees

var elapsed_time: float = 0.0
var initial_angle: float = 0.0
var current_laser: Bullet
var rotation_angle_rad: float = 0.0  # Cached radians value
var start_rotate_delay : float = 0.0
var rotate_duration : float = 0.0

func enter() -> void:
	p.animatedSprite2D.play('glow')
	elapsed_time = 0.0
	start_rotate_delay = laser.laser_width / laser.animate_width_speed
	rotate_duration = laser.time_laser_active - start_rotate_delay
	var direction_to_player := Main.player.global_position - laser_spawn_point.global_position
	rotation_angle_rad = deg_to_rad(rotation_angle_degrees)
	
	initial_angle = direction_to_player.angle() + PI * 2 - rotation_angle_rad / 2
	
	current_laser = laser.bullet_scene.instantiate()
	laser_spawn_point.add_child(current_laser)
	current_laser.initialize(laser, initial_angle)
	current_laser.signal_bullet_removed.connect(_on_bullet_remove)
	
	await get_tree().process_frame
	
	if p.animatedSprite2D.flip_h:
		attack_anim_player.play('laser_2')
	else:
		attack_anim_player.play('laser')

func physics_update(delta: float):
	p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)
	
	elapsed_time += delta
	if elapsed_time <= laser.time_laser_active:
		if elapsed_time <= start_rotate_delay:
			current_laser.rotation = initial_angle
		else:
			var rotation_time = elapsed_time - start_rotate_delay
			if rotation_time <= rotate_duration:
				var rotation_progress = rotation_time / (rotate_duration / 2.0)
				if rotation_progress <= 1.0:
					current_laser.rotation = initial_angle + rotation_progress * rotation_angle_rad
				else:
					current_laser.rotation = initial_angle + rotation_angle_rad - (rotation_progress - 1.0) * rotation_angle_rad
	
	p.physics_update(delta)

func _on_bullet_remove() -> void:
	if current_laser:
		current_laser.queue_free()
		current_laser = null
		sm.on_child_transition(self, "Hostile")
	else:
		print("current_laser is null")

func exit() -> void:
	attack_anim_player.play_backwards('laser')
