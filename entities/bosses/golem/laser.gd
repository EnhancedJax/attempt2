extends State

@export var laser : LaserBulletProps
@export var laser_spawn_point : Marker2D
@export_range(0, 360) var rotation_angle_degrees : float = 180.0  # Rotation angle in degrees

var elapsed_time: float = 0.0
var initial_angle: float = 0.0
var current_laser: Bullet
var rotation_angle_rad: float = 0.0  # Cached radians value

func enter() -> void:
	elapsed_time = 0.0
	var direction_to_player := Main.player.global_position - laser_spawn_point.global_position
	rotation_angle_rad = deg_to_rad(rotation_angle_degrees)
	
	initial_angle = direction_to_player.angle() + PI * 2 - rotation_angle_rad / 2
	
	current_laser = laser.bullet_scene.instantiate()
	laser_spawn_point.add_child(current_laser)
	current_laser.initialize(laser, initial_angle)
	current_laser.signal_bullet_removed.connect(rsignal_bullet_remove)

func physics_update(delta: float):
	p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)
	
	elapsed_time += delta
	if elapsed_time <= laser.time_laser_active:
		var rotation_progress = elapsed_time / (laser.time_laser_active / 2.0)
		if rotation_progress <= 1.0:
			current_laser.rotation = initial_angle + rotation_progress * rotation_angle_rad
		else:
			current_laser.rotation = initial_angle + rotation_angle_rad - (rotation_progress - 1.0) * rotation_angle_rad
	
	p.physics_update(delta)

func rsignal_bullet_remove() -> void:
	if current_laser:
		current_laser.queue_free()
		current_laser = null
		sm.on_child_transition(self, "Hostile")
	else:
		print("current_laser is null")
