class_name ProjectileBullet
extends Bullet

@export var sprite_2d : Sprite2D
@export var shadow_sprite_2d : Sprite2D
@export var collision_shape_2d : CollisionShape2D

var bullet_data : ProjectileBulletProps
var hit_particle : PackedScene
var life_time_timer : Timer
var velocity : Vector2
var remaining_pierce_count : int = 0
var remaining_bounce_count : int = 0
var ATTACK : AttackBase

func initialize(_bullet_data: Variant, _start_rotation: float):
	print('[Projectile] Initialized with data:')
	bullet_data = _bullet_data as ProjectileBulletProps

	# Initialize ATTACK interface
	if bullet_data.damage > 0:
		ATTACK = AttackBase.new()
		ATTACK.damage = bullet_data.damage
		ATTACK.knockback_vector = Vector2(bullet_data.knockback_magnitude, 0).rotated(_start_rotation)
	
	# Setup sprite texture
	if sprite_2d and bullet_data.sprite_texture:
		sprite_2d.texture = bullet_data.sprite_texture
		
		# Set collision shape size to match sprite texture
		if collision_shape_2d:
			var texture_size = bullet_data.sprite_texture.get_size()
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = texture_size
			collision_shape_2d.shape = rect_shape
	else:
		push_error("Bullet sprite texture is not set or bullet data is missing.")
		return
	
	# Handle shadow sprite
	if shadow_sprite_2d:
		shadow_sprite_2d.visible = bullet_data.has_shadow
		if bullet_data.has_shadow:
			shadow_sprite_2d.texture = bullet_data.sprite_texture
	
	# Set collision layers
	if bullet_data.is_player_bullet:
		self.set_collision_layer_value(3, true)
	else:
		self.set_collision_layer_value(2, true)
	
	# Set collision mask for walls (layer 1)
	self.set_collision_mask_value(1, true)
	
	# Rotate initially
	if bullet_data.should_rotate:
		self.rotation = _start_rotation
	
	# Initialize hit particle
	if bullet_data.hit_particle:
		hit_particle = bullet_data.hit_particle
	
	# Initialie modulate
	if bullet_data.bullet_modulate:
		sprite_2d.modulate = bullet_data.bullet_modulate
	
	# Initialize pierce and bounce counts
	remaining_pierce_count = bullet_data.bullet_pierce_count
	remaining_bounce_count = bullet_data.bullet_bounce_count
	
	# Setup lifetime timer
	if not life_time_timer:
		life_time_timer = Timer.new()
		add_child(life_time_timer)
		life_time_timer.wait_time = bullet_data.life_time
		life_time_timer.one_shot = true
		life_time_timer.timeout.connect(_timeout)
	
	life_time_timer.start()

func _timeout():
	# Emit signal to remove bullet
	signal_bullet_collision.emit()
	_handle_remove()

func _handle_remove():
	_disable()
	var particle_instance = _emit_particle()
	if particle_instance:
		await particle_instance.finished
	signal_bullet_removed.emit()

func _emit_particle() -> Node2D:
	if hit_particle:
		var particle_instance = hit_particle.instantiate()
		self.add_child(particle_instance)
		return particle_instance
	return null

# This function will be called by hurtbox when it detects the bullet
func handle_hit() -> void:
	signal_bullet_collision.emit()
	_emit_particle()
	
	# Handle piercing logic
	if remaining_pierce_count > 0:
		remaining_pierce_count -= 1
		# We return false to indicate the bullet should continue
		return
	else:
		# No more piercing, handle removal
		_handle_remove()
		# We return true to indicate the bullet was destroyed
		return

func _physics_process(delta: float) -> void:
	shadow_sprite_2d.global_position = self.global_position + Vector2(0, 8)
	shadow_sprite_2d.global_rotation = self.global_rotation
	var collision : KinematicCollision2D = move_and_collide(self.velocity * delta)
	if collision:
		signal_bullet_collision.emit()
		
		 # Only handle wall bouncing here (walls are on layer 1)
		if remaining_bounce_count > 0:
			remaining_bounce_count -= 1
			# Calculate reflection and update velocity
			var reflection = velocity.bounce(collision.get_normal())
			velocity = reflection
			
			_emit_particle()
				
			# Update rotation to match new direction if bullet should rotate
			if bullet_data.should_rotate:
				self.rotation = velocity.angle()
		else:
			# No more bouncing, handle regular removal
			_handle_remove()

func _disable() -> void:
	print('[Projectile] Disabling bullet')
	self.process_mode = Node.PROCESS_MODE_DISABLED
	self.freeze = true
	sprite_2d.visible = false
	shadow_sprite_2d.visible = false
	life_time_timer.stop()
