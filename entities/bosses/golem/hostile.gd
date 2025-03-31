extends State

# New vars for movement behavior
@export var IDEAL_DISTANCE := 200.0  # Distance to maintain from player
@export var DISTANCE_TOLERANCE := 30.0  # How much deviation from ideal distance is acceptable
@export var STRAFE_SPEED := 100.0
@export var STRAFE_TIME := 1.5  # Time to strafe before changing states

var strafe_direction := 1.0  # 1 for right, -1 for left
var strafe_timer := 0.0
var last_attack_state := ""  # Track the last attack state used

func enter():
	sm.animatedSprite.play("idle")
	randomize()
	p = sm.parent
	strafe_timer = 0.0
	strafe_direction = 1.0 if randf() > 0.5 else -1.0
	
func physics_update(delta : float):
	var player = Main.player
	var can_see_player = false
	
	# Cast rays in a fan pattern to check visibility
	for i in range(-1, 2):
		var space_state = sm.parent.get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			sm.parent.global_position,
			player.global_position + Vector2(i * 16, 0),
			2
		)
		query.exclude = [sm.parent]
		var result = space_state.intersect_ray(query)
		
		if result and result.collider == player:
			can_see_player = true
			break
	
	if can_see_player:
		# Calculate distance and direction to player
		var to_player = player.global_position - sm.parent.global_position
		var distance = to_player.length()
		var direction = to_player.normalized()
		
		# Update strafe timer
		strafe_timer += delta
		
		# After strafe time, transition to a random attack state
		if strafe_timer >= STRAFE_TIME:
			var available_states = ["Shoot1", "Shoot2", "Laser"]
			
			# Remove the last used state from options if it exists
			if last_attack_state in available_states:
				available_states.erase(last_attack_state)
			
			# Pick a random state from remaining options
			var next_state = available_states[randi() % available_states.size()]
			last_attack_state = next_state
			sm.on_child_transition(self, 'Laser')
			return
		
		# Movement vector
		var movement = Vector2.ZERO
		
		# Add strafe movement (perpendicular to player direction)
		var strafe = Vector2(-direction.y, direction.x) * strafe_direction
		movement += strafe * STRAFE_SPEED
		
		# Add movement towards or away from player based on distance
		if distance > IDEAL_DISTANCE + DISTANCE_TOLERANCE:
			movement += direction * STRAFE_SPEED
		elif distance < IDEAL_DISTANCE - DISTANCE_TOLERANCE:
			movement -= direction * STRAFE_SPEED
		
		# Apply movement using move_toward
		p.velocity = p.velocity.move_toward(movement, 40000 * delta)
	else:
		p.velocity = Vector2.ZERO
	
	# Call physics_update on sm.parent
	p.physics_update(delta)
