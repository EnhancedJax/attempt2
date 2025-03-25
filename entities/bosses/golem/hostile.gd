extends State

# New vars for movement behavior
@export var IDEAL_DISTANCE := 200.0  # Distance to maintain from player
@export var DISTANCE_TOLERANCE := 30.0  # How much deviation from ideal distance is acceptable
@export var STRAFE_SPEED := 100.0
@export var STRAFE_CHANGE_TIME := 1.5  # Time before changing strafe direction
@export var MELEE_RANGE : float = 64
@export var CHANGE_MODE_TIME : float = 0.5
var strafe_direction := 1.0  # 1 for right, -1 for left
var strafe_change_timer := 0.0
var change_mode_timer := 0.0

func enter():
	sm.animatedSprite.play("idle")
	randomize()
	p = sm.parent
	change_mode_timer = 0.0
	
func physics_update(delta : float):
	var player = Main.player
	var can_see_player = false
	
	# Update strafe timer and direction
	strafe_change_timer += delta
	if strafe_change_timer >= STRAFE_CHANGE_TIME:
		strafe_change_timer = 0.0
		strafe_direction = -strafe_direction if randf() > 0.3 else strafe_direction
	
	# Cast rays in a fan pattern
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
		
		 # Check if player is in melee range
		
		# Randomly wait to change to Shoot state
		change_mode_timer += delta
		if change_mode_timer >= CHANGE_MODE_TIME:
			change_mode_timer = 0.0
			if randf() > 0.5:
				sm.on_child_transition(self, "Shoot")
				return
				
		var player_in_melee_range = distance <= MELEE_RANGE
		
		if player_in_melee_range:
			# Transition to melee attack state
			sm.on_child_transition(self, "Melee")
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
