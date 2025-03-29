class_name BulletSpawner
extends RayCast2D

@export var bullet_props : BulletProps
@export var bullet_pattern : BulletSpawnPattern

signal signal_shot()
signal signal_bullet_removed()
signal signal_all_bullets_removed()

var active_bullets : Array = []
var can_shoot : bool = true
var shoot_timer : Timer
var bullet_timer : Timer
var shot_queue : Array = []

func _ready():
	if not bullet_props:
		push_error("[BulletSpawner] No bullet properties assigned")
		return
	if not bullet_pattern:
		push_error("[BulletSpawner] No bullet pattern assigned")
		return
	# Create timers
	shoot_timer = Timer.new()
	bullet_timer = Timer.new()
	
	shoot_timer.one_shot = true
	bullet_timer.one_shot = true
	
	add_child(shoot_timer)
	add_child(bullet_timer)
	
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	bullet_timer.timeout.connect(_on_bullet_timer_timeout)

## Shot based on the rotation and position of the spawner.
func shoot() -> bool:
	if not can_shoot or not bullet_props or not bullet_pattern:
		return false
	
	can_shoot = false
	_spawn_bullets()
	signal_shot.emit()
	
	# Start shoot cooldown
	if bullet_pattern.time_between_fire > 0:
		shoot_timer.wait_time = bullet_pattern.time_between_fire
		shoot_timer.start()
	else:
		can_shoot = true
	return true

func _spawn_bullets() -> void:
	var base_pos = _get_base_spawn_position()
	var base_rot = global_rotation
	
	# Add bullets to shot queue based on pattern
	shot_queue.clear()
	
	# If continuous positioning is enabled, only set up the first bullet
	# The rest will get their positions when they are spawned
	if bullet_pattern.continous_shoot_position and bullet_pattern.time_between_bullets > 0:
		# Create a single bullet for now, the rest will be created dynamically
		shot_queue.append({
			"position": base_pos,
			"rotation": base_rot
		})
		# Store pattern info to generate positions later
		shot_queue.append({
			"pattern_type": bullet_pattern.get_class(),
			"bullets_left": bullet_pattern.amount_of_bullets - 1
		})
	else:
		# Create positions and rotations based on pattern type
		if bullet_pattern is PatternArc:
			_setup_arc_pattern(base_pos, base_rot)
		elif bullet_pattern is PatternLine:
			_setup_line_pattern(base_pos, base_rot)
		elif bullet_pattern is PatternPoints:
			_setup_points_pattern(base_pos, base_rot)
		else:
			# Default - single bullet
			shot_queue.append({
				"position": base_pos,
				"rotation": base_rot
			})
	
	# Start spawning bullets from queue
	if shot_queue.size() > 0:
		_spawn_next_bullet()

func _setup_arc_pattern(base_pos: Vector2, base_rot: float) -> void:
	var pattern = bullet_pattern as PatternArc
	var bullets = bullet_pattern.amount_of_bullets
	
	if bullets <= 1:
		shot_queue.append({
			"position": base_pos,
			"rotation": base_rot
		})
		return
		
	var angle_start = base_rot - deg_to_rad(pattern.arc_angle / 2)
	var angle_step = deg_to_rad(pattern.arc_angle) / (bullets - 1)
	
	for i in range(bullets):
		var angle = angle_start + angle_step * i
		shot_queue.append({
			"position": base_pos,
			"rotation": angle
		})

func _setup_line_pattern(base_pos: Vector2, base_rot: float) -> void:
	var pattern = bullet_pattern as PatternLine
	var bullets = bullet_pattern.amount_of_bullets
	var distance = pattern.distance_between_bullets
	
	# Calculate perpendicular direction for line layout
	var perp_dir = Vector2(cos(base_rot + PI/2), sin(base_rot + PI/2))
	var start_offset = perp_dir * distance * (bullets - 1) / 2
	
	for i in range(bullets):
		var pos = base_pos - start_offset + perp_dir * distance * i
		shot_queue.append({
			"position": pos,
			"rotation": base_rot
		})

func _setup_points_pattern(base_pos: Vector2, base_rot: float) -> void:
	var pattern = bullet_pattern as PatternPoints
	var bullets_per_point = ceil(float(bullet_pattern.amount_of_bullets) / pattern.points.size())
	
	for point in pattern.points:
		for _i in range(bullets_per_point):
			var rot = base_rot
			if pattern.randomized_angle_spread > 0:
				rot += randf_range(-deg_to_rad(pattern.randomized_angle_spread), 
					deg_to_rad(pattern.randomized_angle_spread))
			
			shot_queue.append({
				"position": base_pos + point.rotated(base_rot),
				"rotation": rot
			})
	
	# Trim excess bullets if needed
	while shot_queue.size() > bullet_pattern.amount_of_bullets:
		shot_queue.pop_back()

func _spawn_next_bullet() -> void:
	if shot_queue.size() == 0:
		return
		
	var bullet_data = shot_queue.pop_front()
	
	# Check if this is pattern info for continuous shooting
	if bullet_data.has("bullets_left"):
		var bullets_left = bullet_data.bullets_left
		var pattern_type = bullet_data.pattern_type
		
		# Get updated position and rotation
		var updated_pos = _get_base_spawn_position()
		var updated_rot = global_rotation
		
		# Generate next bullet with updated position
		shot_queue.insert(0, {
			"position": updated_pos,
			"rotation": updated_rot
		})
		
		# Update the pattern info for next bullets
		if bullets_left > 1:
			shot_queue.append({
				"pattern_type": pattern_type,
				"bullets_left": bullets_left - 1
			})
		
		# Restart the function to handle the actual bullet we just added
		_spawn_next_bullet()
		return
	
	var bullet_scene = bullet_props.bullet_scene

	# Instantiate the bullet
	if not bullet_scene:
		push_error("BulletSpawner: No bullet scene assigned")
		return
	
	var bullet_instance = bullet_scene.instantiate() as Bullet
	if not bullet_instance:
		push_error("BulletSpawner: Failed to instantiate bullet")
		return
		
	# Add to scene
	Main.spawn_node(bullet_instance, bullet_data.position)
	
	# Set position and initialize
	bullet_instance.initialize(bullet_props, bullet_data.rotation)
	
	# Connect signals
	bullet_instance.signal_bullet_collision.connect(_on_bullet_collision.bind(bullet_instance))
	bullet_instance.signal_bullet_removed.connect(_on_bullet_removed.bind(bullet_instance))
	
	# Set initial velocity but wait before moving if needed
	var velocity_direction = Vector2(cos(bullet_data.rotation), sin(bullet_data.rotation))
	var final_velocity = velocity_direction * bullet_pattern.speed
	
	if bullet_pattern.time_before_move > 0:
		bullet_instance.velocity = Vector2.ZERO
		
		# Create a timer for this bullet to start moving
		var move_timer = get_tree().create_timer(bullet_pattern.time_before_move)
		move_timer.timeout.connect(func(): bullet_instance.velocity = final_velocity)
	else:
		bullet_instance.velocity = final_velocity
	
	active_bullets.append(bullet_instance)
	
	# Schedule next bullet if queue not empty
	if shot_queue.size() > 0 and bullet_pattern.time_between_bullets > 0:
		bullet_timer.wait_time = bullet_pattern.time_between_bullets
		bullet_timer.start()
	else:
		# Spawn all bullets at once
		while shot_queue.size() > 0:
			_spawn_next_bullet()

## if not colliding, spawn at tip, otherwise, spawn at base
func _get_base_spawn_position() -> Vector2:
	if not is_colliding():
		var scaled_target = Vector2(target_position.x * abs(global_scale.x), target_position.y * abs(global_scale.y))
		return global_position + scaled_target.rotated(self.global_rotation)
	else:
		return global_position

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_bullet_timer_timeout() -> void:
	_spawn_next_bullet()

func _on_bullet_collision(bullet: Bullet) -> void:
	pass

func _on_bullet_removed(bullet: Bullet) -> void:
	if bullet in active_bullets:
		active_bullets.erase(bullet)
		signal_bullet_removed.emit()
		bullet.queue_free()
		
		if active_bullets.is_empty():
			signal_all_bullets_removed.emit()
