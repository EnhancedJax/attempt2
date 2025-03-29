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

var pierce_count : int = -1  # Default to infinite pierce
var hit_objects = []  # Track objects that have been hit

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
	
	# Setup raycast direction
	raycast.target_position = Vector2.RIGHT.rotated(_start_rotation) * MAX_DISTANCE
	
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
	reach_collision_timer.wait_time = bullet_data.time_laser_reach_collision if bullet_data.time_laser_reach_collision > 0 else 0.01
	reach_collision_timer.timeout.connect(_on_reach_collision_timeout)
	
	# Timer for how long the laser stays active at full length
	active_time_timer = Timer.new()
	add_child(active_time_timer)
	active_time_timer.one_shot = true
	active_time_timer.wait_time = bullet_data.time_laser_active if bullet_data.time_laser_active > 0 else 0.01
	active_time_timer.timeout.connect(_on_active_time_timeout)

func start_laser_sequence():
	# Step 1: Start growing the laser to its collision point
	reach_collision_timer.start()

func _on_reach_collision_timeout():
	perform_raycast()
	signal_collision_reached.emit()
	# active_time_timer.start()

func _on_active_time_timeout():
	pass
# 	signal_activation_complete.emit()
# 	# Disable collision when active time is over
# 	# disable_collision()
# 	start_fade_out()

func perform_raycast():
	# Reset hit objects list
	hit_objects.clear()
	
	# Get the end point considering pierce
	var end_point = get_endpoint_with_pierce()
	
	# Update line points
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(to_local(end_point))
	
	# Setup collision shape for the laser
	setup_collision_shape(end_point)
	
	# If time_laser_active is -1, disable collision after one frame
	if bullet_data.time_laser_active < 0:
		# Use a CallDeferred to ensure physics processing completes first

		await get_tree().process_frame
		await get_tree().physics_frame

		call_deferred("_disable_collision")
		start_fade_out()

func get_endpoint_with_pierce() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var ray_origin = global_position
	var ray_direction = raycast.target_position.normalized()
	var max_distance = MAX_DISTANCE
	var current_pierce = pierce_count
	
	# Track objects to exclude in subsequent ray casts
	var excluded_rids = []
	
	# Prepare the default endpoint (no collision)
	var final_endpoint = ray_origin + ray_direction * max_distance
	
	# If pierce is 0, just use the original raycast once
	if current_pierce == 0:
		raycast.force_raycast_update()
		if raycast.is_colliding():
			final_endpoint = raycast.get_collision_point()
			var collider = raycast.get_collider()
			print(collider)
			hit_objects.append(collider)
			
			# Spawn hit particle at collision point
			if bullet_data.hit_particle:
				var particle = bullet_data.hit_particle.instantiate()
				add_child(particle)
				particle.global_position = final_endpoint
				
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
		hit_objects.append(collider)
		
		# Spawn hit particle at the collision point
		if bullet_data.hit_particle:
			var particle = bullet_data.hit_particle.instantiate()
			add_child(particle)
			particle.global_position = result.position
		
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

# The original get_endpoint function is no longer needed, but kept for reference
func get_endpoint() -> Vector2:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		return raycast.get_collision_point()
	else:
		return global_position + raycast.target_position

func setup_collision_shape(end_point: Vector2):
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

func start_fade_out():
	animation_player.play("fade")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade":
		signal_bullet_removed.emit()

func _physics_process(delta: float) -> void:
	# Can add effects like laser wiggling or updating based on source movement here
	pass

func _disable():
	self.process_mode = Node.PROCESS_MODE_DISABLED
	line.visible = false
	set_physics_process(false)
	collision_shape_2d.disabled = true
	reach_collision_timer.stop()
	active_time_timer.stop()
