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

var velocity : Vector2 = Vector2.ZERO # unused, but needed for assignment by spawner
var current_length : float = 0.0
var target_end_point : Vector2 = Vector2.ZERO
var impact_colliders : Array[CollisionShape2D] = []

var pierce_count : int = -1  # Default to infinite pierce

# Animation properties
var current_width : float = 0.0
var target_width : float = 1.0
var is_animating_width : bool = false
var is_animating_length : bool = false
var target_length : float = 0.0

var origin_particle_instance : Node2D = null
var laser_particle_instance : Node2D = null
var hit_particle_instance : Node2D = null  # Add this line

signal signal_collision_reached
signal signal_activation_complete

func initialize(_bullet_data: Variant, _start_rotation: float):
	print('[Laser] Initialized with data:')
	bullet_data = _bullet_data as LaserBulletProps

	# Set the global rotation of the entire laser
	global_rotation = _start_rotation

	# Initialize ATTACK interface
	if bullet_data.damage > 0:
		ATTACK = AttackBase.new()
		ATTACK.damage = bullet_data.damage
		ATTACK.knockback_vector = Vector2(bullet_data.knockback_magnitude, 0)
		if bullet_data.time_laser_active > 0:
			ATTACK.damage_tick_interval = bullet_data.damage_tick_interval
	
	# Setup raycast to point right (will be rotated with node)
	raycast.target_position = Vector2.RIGHT * MAX_DISTANCE

	# Setup fade animation duration
	if bullet_data.time_laser_fade <= 0:
		push_error("Laser fade time must be greater than 0.")
		return
	animation_player.speed_scale = 1 / bullet_data.time_laser_fade
	
	# Set pierce count
	pierce_count = bullet_data.laser_pierce_count
	
	# Set up line
	if bullet_data.laser_texture:
		line.texture = bullet_data.laser_texture	
	elif bullet_data.laser_fill_gradient:
		line.gradient = bullet_data.laser_fill_gradient
	
	if bullet_data.line_cap_round:
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	# Initialize width and animation variables
	current_width = 0 if bullet_data.animate_width_speed > 0 else bullet_data.laser_width
	target_width = bullet_data.laser_width
	line.width = current_width
	
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
	
	# Initialize particles
	setup_particles()
	
	# Start the laser sequence
	start_laser_sequence()

func setup_particles():
	# Setup origin point particle if provided
	if bullet_data.origin_point_particle:
		origin_particle_instance = instantiate_and_validate_particle(bullet_data.origin_point_particle)
		if origin_particle_instance:
			add_child(origin_particle_instance)
			origin_particle_instance.emitting = true
	
	# Setup laser body particle if provided
	if bullet_data.laser_particle:
		laser_particle_instance = instantiate_and_validate_particle(bullet_data.laser_particle)
		if laser_particle_instance:
			add_child(laser_particle_instance)
			laser_particle_instance.emitting = true
			# Initial setup - will be properly sized during physics process

func instantiate_and_validate_particle(particle_scene: PackedScene) -> Node2D:
	if not particle_scene:
		return null
		
	var particle_instance = particle_scene.instantiate()
	
	# Validate it's a particle system
	if not (particle_instance is GPUParticles2D or particle_instance is CPUParticles2D):
		push_error("Provided particle scene must be either GPUParticles2D or CPUParticles2D")
		particle_instance.queue_free()
		return null
		
	return particle_instance

func setup_timers():
	active_time_timer = Timer.new()
	add_child(active_time_timer)
	active_time_timer.one_shot = true
	
	# Only use active time timer if not externally controlled
	if not bullet_data.external_control_disable:
		active_time_timer.wait_time = bullet_data.time_laser_active if bullet_data.time_laser_active > 0 else 0.01
		active_time_timer.timeout.connect(_on_active_time_timeout)
		
	# Initialize animation flags
	is_animating_width = bullet_data.animate_width_speed > 0
	is_animating_length = bullet_data.animate_length_speed > 0

func start_laser_sequence():
	# Prepare for width animation if enabled
	if is_animating_width:
		current_width = 0.0
	
	# Initialize line to zero length first
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	
	# Determine if we need length animation and prepare target endpoint
	if is_animating_length:
		current_length = 0.0
		perform_raycast(true)  # Calculate target endpoint after setting initial zero length
		target_length = to_local(target_end_point).length()
	else:
		perform_raycast()
	signal_collision_reached.emit()
	
	if not bullet_data.external_control_disable:
		if bullet_data.time_laser_active > 0:
			active_time_timer.start()
		elif bullet_data.time_laser_active < 0:
			await get_tree().process_frame
			await get_tree().physics_frame
			call_deferred("_disable_collision")
			start_fade_out()

func _physics_process(delta: float) -> void:
	# Handle width animation (purely cosmetic)
	if is_animating_width and bullet_data.animate_width_speed > 0:
		current_width += bullet_data.animate_width_speed * delta
		if current_width >= target_width:
			current_width = target_width
			is_animating_width = false
		line.width = current_width
	
	# Handle length animation (purely cosmetic)
	if is_animating_length and bullet_data.animate_length_speed > 0:
		current_length += bullet_data.animate_length_speed * delta
		
		# Check if we've reached target length
		if current_length >= target_length:
			current_length = target_length
			is_animating_length = false
		
		# Update line visual with current animated length
		var direction = to_local(target_end_point).normalized()
		var animated_end = direction * current_length
		
		# Update line points for visual display only
		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.add_point(animated_end)
	
	# Update laser particle size and position if it exists
	update_laser_particle()

	if bullet_data.continous_cast:
		perform_raycast()
		move_and_collide(Vector2.ZERO)

# Updates the laser particle to match the current laser size
func update_laser_particle():
	if not laser_particle_instance:
		return
		
	var local_end_point = line.points[1] if line.points.size() > 1 else Vector2.ZERO
	
	if local_end_point == Vector2.ZERO:
		# Hide particles if laser has no length
		laser_particle_instance.emitting = false
		return
	
	# Enable particles
	laser_particle_instance.emitting = true
	
	# Position the particles in the middle of the laser
	laser_particle_instance.position = local_end_point / 2
	laser_particle_instance.rotation = local_end_point.angle()
	
	# Scale the particle system to match the laser length
	var length = local_end_point.length()
	if length > 0:
		if laser_particle_instance is GPUParticles2D:
			# For GPU particles, we can use process material's emission box
			var process_material = laser_particle_instance.process_material
			if process_material and process_material is ParticleProcessMaterial:
				var emission_box = Vector3(length / 2, bullet_data.laser_width / 2, 1)
				process_material.emission_box_extents = emission_box
		elif laser_particle_instance is CPUParticles2D:
			# For CPU particles, set the emission box directly
			laser_particle_instance.emission_rect_extents = Vector2(length / 2, bullet_data.laser_width / 2)

func _on_length_animation_timeout():
	# This function is no longer used with speed-based animation
	pass

func _on_width_animation_timeout():
	# This function is no longer used with speed-based animation  
	pass

func _on_active_time_timeout():
	signal_activation_complete.emit()
	_disable_collision()
	start_fade_out()

func perform_raycast(skip_draw_line: bool = false):
	# Get the end point considering pierce
	var end_point = get_endpoint_with_pierce()
	target_end_point = end_point
	
	if not skip_draw_line:
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
		

func get_endpoint_with_pierce() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var ray_origin = global_position
	var ray_direction = Vector2.RIGHT.rotated(global_rotation)
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
			
			 # Handle hit particle
			if bullet_data.hit_particle:
				if bullet_data.continous_cast:
					if not hit_particle_instance:
						hit_particle_instance = bullet_data.hit_particle.instantiate()
						add_child(hit_particle_instance)
					hit_particle_instance.global_position = final_endpoint
				else:
					var particle = bullet_data.hit_particle.instantiate()
					add_child(particle)
					particle.global_position = final_endpoint
			
		return final_endpoint
	
	# For infinite pierce (-1) or limited pierce (> 0)
	while true:
		var query = PhysicsRayQueryParameters2D.create(
			ray_origin, 
			ray_origin + ray_direction * max_distance, 
			raycast.collision_mask,
			excluded_rids
		)
		
		var result = space_state.intersect_ray(query)
		
		if not result:
			break
			
		var collider = result.collider
	
		# Handle hit particle
		if bullet_data.hit_particle:
			if bullet_data.continous_cast:
				if not hit_particle_instance:
					hit_particle_instance = bullet_data.hit_particle.instantiate()
					add_child(hit_particle_instance)
				hit_particle_instance.global_position = result.position
			else:
				var particle = bullet_data.hit_particle.instantiate()
				add_child(particle)
				particle.global_position = result.position
		
		if collider is TileMapLayer:
			final_endpoint = result.position
			break
		
		excluded_rids.append(collider.get_rid())
		
		if current_pierce > 0:
			current_pierce -= 1
			if current_pierce == 0:
				final_endpoint = result.position
				break
	
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
	rectangle.size = Vector2(local_end.length() + 16, bullet_data.laser_width)
	collision_shape_2d.shape = rectangle
	# Position at half length along X axis (local space is now aligned with laser)
	collision_shape_2d.position = Vector2(local_end.length() / 2, 0)
	# No need to rotate the collision shape as we're in local space
	collision_shape_2d.rotation = 0
	collision_shape_2d.disabled = false

func _disable_collision():
	print('[Laser] Disabling collision')
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
	if hit_particle_instance:
		hit_particle_instance.queue_free()
		hit_particle_instance = null
	animation_player.play("fade")
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade":
		signal_bullet_removed.emit()

func _disable():
	self.process_mode = Node.PROCESS_MODE_DISABLED
	line.visible = false
	set_physics_process(false)
	_disable_collision()
	active_time_timer.stop()
	
	is_animating_width = false
	is_animating_length = false
	
	# Stop particle emission
	if origin_particle_instance:
		origin_particle_instance.emitting = false
	if laser_particle_instance:
		laser_particle_instance.emitting = false

# External control method
func laser_stop():
	if bullet_data.external_control_disable:
		_disable_collision()
		start_fade_out()
