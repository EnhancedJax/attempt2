class_name Bullet 
extends RigidBody2D

signal signal_bullet_collision()
signal sginal_bullet_removed()

@export var sprite_2d : Sprite2D
@export var shadow_sprite_2d : Sprite2D
@export var collision_shape_2d : CollisionShape2D

var bullet_data : BulletProps
var hit_particle : CPUParticles2D
var life_time_timer : Timer
var velocity : Vector2
var remaining_pierce_count : int = 0
var remaining_bounce_count : int = 0
var ATTACK : AttackBase

func initialize(_bullet_data: BulletProps, _start_rotation: float):
	
	bullet_data = _bullet_data

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
	
	# Rotate initially
	if bullet_data.should_rotate:
		self.rotation = _start_rotation
	
	# Initialize hit particle
	if bullet_data.hit_particle:
		hit_particle = bullet_data.hit_particle.instantiate()
		add_child(hit_particle)
	
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
	if hit_particle:
		hit_particle.emitting = true
		await hit_particle.finished
	sginal_bullet_removed.emit()

func _physics_process(delta: float) -> void:
	shadow_sprite_2d.global_position = self.global_position + Vector2(0, 8)
	shadow_sprite_2d.global_rotation = self.global_rotation
	var collision : KinematicCollision2D = move_and_collide(self.velocity * delta)
	if collision:
		signal_bullet_collision.emit()
		
		# Handle piercing and bouncing logic
		if remaining_pierce_count > 0:
			remaining_pierce_count -= 1
			# Show hit effect but continue moving
			if hit_particle:
				var particle_instance = hit_particle.duplicate()
				get_parent().add_child(particle_instance)
				particle_instance.global_position = collision.get_position()
				particle_instance.emitting = true
		elif remaining_bounce_count > 0:
			remaining_bounce_count -= 1
			# Calculate reflection and update velocity
			var reflection = velocity.bounce(collision.get_normal())
			velocity = reflection
			
			# Optionally show bounce effect
			if hit_particle:
				var particle_instance = hit_particle.duplicate()
				get_parent().add_child(particle_instance)
				particle_instance.global_position = collision.get_position()
				particle_instance.emitting = true
				
			# Update rotation to match new direction if bullet should rotate
			if bullet_data.should_rotate:
				self.rotation = velocity.angle()
		else:
			# No more piercing or bouncing, handle regular removal
			_handle_remove()

func _disable() -> void:
	self.process_mode = Node.PROCESS_MODE_DISABLED
	sprite_2d.visible = false
	shadow_sprite_2d.visible = false
	life_time_timer.stop()
