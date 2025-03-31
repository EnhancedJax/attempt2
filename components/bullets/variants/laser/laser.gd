class_name LaserBullet
extends Bullet

@export var collision_shape_2d : CollisionShape2D
@export var line : Line2D
@export var raycast: RayCast2D
@export var animation_player: AnimationPlayer


const MAX_DISTANCE = 1000

var bullet_data : LaserBulletProps
var ATTACK : AttackBase
var active_time_timer : Timer
var reach_collision_timer : Timer

var velocity : Vector2 = Vector2.ZERO
var current_length : float = 0.0
var target_end_point : Vector2 = Vector2.ZERO
var impact_colliders : Array[CollisionShape2D] = []

var pierce_count : int = -1  # Default to infinite pierce
var hit_objects = []  # Track objects that have been hit
var collision_points : Array[Vector2] = []

signal signal_collision_reached
signal signal_activation_complete

func initialize(_bullet_data: Variant, _start_rotation: float):
	print('[Laser] Initialized with data:')
	bullet_data = _bullet_data as LaserBulletProps

	# Initialize ATTACK interface
	if bullet_data.damage > 0:
		ATTACK = AttackBase.new()
		ATTACK.damage = bullet_data.damage
		ATTACK.knockback_vector = Vector2(bullet_data.knockback_magnitude, 0).rotated(_start_rotation)
		ATTACK.damage_tick_interval = bullet_data.damage_tick_interval  # Pass ticking interval to ATTACK
	
	# Setup raycast direction
	raycast.target_position = Vector2.RIGHT.rotated(_start_rotation) * MAX_DISTANCE

	# Setup fade animation duration
	if bullet_data.time_laser_fade <= 0:
		push_error("Laser fade time must be greater than 0.")
		return
	animation_player.speed_scale = 1 / bullet_data.time_laser_fade
	
	# Set pierce count
	pierce_count = bullet_data.laser_pierce_count
	
	# Set up line
	if bullet_data.laser_fill_gradient:
		line.gradient = bullet_data.laser_fill_gradient
	line.width = bullet_data.laser_width
	
	# Set collision layers
	if bullet_data.is_player_bullet:
		self.set_collision_layer_value(3, true)
		raycast.set_collision_mask_value(3, true) 
	else:
		self.set_collision_layer_value(2, true)
		raycast.set_collision_mask_value(2, true)
	
	# Initialize line to zero length initially
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	
	# Set modulate
	if bullet_data.bullet_modulate:
		line.modulate = bullet_data.bullet_modulate
	
	# Set up timers for staged laser behavior
	setup_timers()
	
	# Start the laser sequence
	start_laser_sequence()

func setup_timers():
	# Timer for how long to wait until the laser reaches its collision point
	reach_collision_timer = Timer.new()
	add_child(reach_collision_timer)
	reach_collision_timer.one_shot = true
	reach_collision_timer.wait_time = 0.01  # Just a minimal delay for instant lasers
	reach_collision_timer.timeout.connect(_on_reach_collision_timeout)
	
	# Timer for how long the laser stays active at full length
	active_time_timer = Timer.new()
	add_child(active_time_timer)
	active_time_timer.one_shot = true
	
	# Only use active time timer if not externally controlled
	if not bullet_data.external_control_disable:
		active_time_timer.wait_time = bullet_data.time_laser_active if bullet_data.time_laser_active > 0 else 0.01
		active_time_timer.timeout.connect(_on_active_time_timeout)

func start_laser_sequence():
	# Instant laser: immediately calculate collision endpoint.
	reach_collision_timer.start()

func _on_reach_collision_timeout():
	perform_raycast()
	signal_collision_reached.emit()
	
	# Start active timer if not externally controlled
	if not bullet_data.external_control_disable:
		if bullet_data.time_laser_active > 0:
			active_time_timer.start()
		elif bullet_data.time_laser_active < 0:
			# Use a CallDeferred to ensure physics processing completes first
			await get_tree().process_frame
			await get_tree().physics_frame
			call_deferred("_disable_collision")
			start_fade_out()

func _on_active_time_timeout():
	signal_activation_complete.emit()
	_disable_collision()
	start_fade_out()

func perform_raycast(calculate_only: bool = false):
	# Reset hit objects list if not just calculating
	if not calculate_only:
		hit_objects.clear()
	
	# Get the end point considering pierce
	var end_point = get_endpoint_with_pierce(calculate_only)
	target_end_point = end_point
	
	if not calculate_only:
		# Update line points
		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.add_point(to_local(end_point))
		
		# Setup collision shape for the laser
		setup_collision_shape(end_point)
		
		# If time_laser_active is -1, disable collision after one frame
		if not bullet_data.external_control_disable and bullet_data.time_laser_active < 0:
			await get_tree().process_frame
			await get_tree().physics_frame
			call_deferred("_disable_collision")
			start_fade_out()

func get_endpoint_with_pierce(calculate_only: bool = false) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var ray_origin = global_position
	var ray_direction = raycast.target_position.normalized()
	var max_distance = MAX_DISTANCE
	var current_pierce = pierce_count
	
	# Track objects to exclude in subsequent ray casts
	var excluded_rids = []
	
	# Prepare the default endpoint (no collision)
	var final_endpoint = ray_origin + ray_direction * max_distance
	
	# Clear existing collision points if they exist
	collision_points.clear()
	
	# If pierce is 0, just use the original raycast once
	if current_pierce == 0:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			final_endpoint = raycast.get_collision_point()
			var collider = raycast.get_collider()
			
			if not calculate_only:
				print(collider)
				hit_objects.append(collider)
				
				# Spawn hit particle at collision point
				if bullet_data.hit_particle:
					var particle = bullet_data.hit_particle.instantiate()
					add_child(particle)
					particle.global_position = final_endpoint
			
			# Add to collision points array for collide_at_impact
			collision_points.append(final_endpoint)
			
		return final_endpoint
	
	# For infinite pierce (-1) or limited pierce (> 0), we need to handle multiple hits
	while true:
		# Create parameters for raycast with current excluded objects
		var query = PhysicsRayQueryParameters2D.create(
			ray_origin, 
			ray_origin + ray_direction * max_distance, 
			raycast.collision_mask,
			excluded_rids
		)
		
		var result = space_state.intersect_ray(query)
		
		if not result:
			# No more hits, stop at the maximum distance
			break
			
		var collider = result.collider
		
		if not calculate_only:
			hit_objects.append(collider)
		
			# Spawn hit particle at the collision point
			if bullet_data.hit_particle:
				var particle = bullet_data.hit_particle.instantiate()
				add_child(particle)
				particle.global_position = result.position
		
		# Add this collision point to our array
		collision_points.append(result.position)
		
		# Always stop at walls regardless of pierce count
		if collider is TileMapLayer:
			final_endpoint = result.position
			break
		
		# Add this object to the exclude list for the next raycast
		excluded_rids.append(collider.get_rid())
		
		# If pierce count is positive, decrement it
		if current_pierce > 0:
			current_pierce -= 1
			
			# If we've used all pierces, stop at this collision point
			if current_pierce == 0:
				final_endpoint = result.position
				break
		
		# For infinite pierce (-1), we only stop when hitting a wall
		# which is handled above
	
	return final_endpoint

func get_endpoint() -> Vector2:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return global_position + raycast.target_position

func setup_collision_shape(end_point: Vector2):
	# Clean up any existing impact colliders
	for collider in impact_colliders:
		if is_instance_valid(collider):
			collider.queue_free()
	impact_colliders.clear()
	# Always use beam collision since "collide_at_impact" is deprecated
	setup_beam_collision(end_point)

func setup_beam_collision(end_point: Vector2):
	if not collision_shape_2d:
		return
		
	var local_end = to_local(end_point)
	var rectangle = RectangleShape2D.new()
	# Set size based on actual distance to endpoint, not MAX_DISTANCE
	rectangle.size = Vector2(local_end.length(), bullet_data.laser_width)
	collision_shape_2d.shape = rectangle
	collision_shape_2d.position = local_end / 2
	collision_shape_2d.rotation = local_end.angle()
	collision_shape_2d.disabled = false

func _disable_collision():
	# Disable collision layers
	self.set_collision_layer_value(2, false)
	self.set_collision_layer_value(3, false)
	
	# Disable the collision shape
	if collision_shape_2d:
		collision_shape_2d.disabled = true
	
	# Disable impact colliders
	for collider in impact_colliders:
		if is_instance_valid(collider):
			collider.disabled = true

func start_fade_out():
	animation_player.play("fade")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade":
		signal_bullet_removed.emit()

func _disable():
	self.process_mode = Node.PROCESS_MODE_DISABLED
	line.visible = false
	set_physics_process(false)
	_disable_collision()
	reach_collision_timer.stop()
	active_time_timer.stop()

# External control method
func laser_stop():
	if bullet_data.external_control_disable:
		_disable_collision()
		start_fade_out()
