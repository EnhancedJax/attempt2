extends State

@export var BURST_DURATION := 0.5
@export var BURST_COOLDOWN := 2.0
var burst_timer := 0.0
var cooldown_timer := 0.0
var is_bursting := false

# New vars for movement behavior
@export var IDEAL_DISTANCE := 200.0  # Distance to maintain from player
@export var DISTANCE_TOLERANCE := 30.0  # How much deviation from ideal distance is acceptable
@export var STRAFE_SPEED := 100.0
@export var STRAFE_CHANGE_TIME := 1.5  # Time before changing strafe direction
var strafe_direction := 1.0  # 1 for right, -1 for left
var strafe_change_timer := 0.0

func enter():
	sm.animatedSprite.play("default")
	randomize()
	
func physics_update(delta : float):
	if p.velocity.length() > 0:
		p.physics_update(delta)
	
	var player = Main.player
	var can_see_player = false
	
	# Update timers
	if is_bursting:
		burst_timer += delta
		if burst_timer >= BURST_DURATION:
			is_bursting = false
			burst_timer = 0.0
	else:
		cooldown_timer += delta
		if cooldown_timer >= BURST_COOLDOWN:
			is_bursting = true
			cooldown_timer = 0.0
	
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
		
		# Handle weapon use during burst
		if is_bursting:
			sm.parent.weapon_node.handle_use(delta, false, false, true)
	else:
		p.velocity = Vector2.ZERO
	
	# Call physics_update on sm.parent
	p.physics_update(delta)
