extends State

@export var laser_duration : float = 2.0
@export var walk_speed : float = 50

var timer : float = 0.0

func enter() -> void:
	timer = 0.0
	# Activate laser attack
	# This is a placeholder - implement actual laser behavior
	p.weapon_node.handle_use_custom(0, 3, true) # Assuming mode 3 is for laser

func update(delta: float) -> void:
	timer += delta
	if timer >= laser_duration:
		# Transition back to Hostile
		sm.on_child_transition(self, "Hostile")
		
func physics_update(delta : float):
	var player = Main.player
	
	# Calculate direction to player
	var to_player = player.global_position - sm.parent.global_position
	var direction = to_player.normalized()
	
	# Move more slowly while firing laser
	p.velocity = direction * walk_speed
	
	# Call physics_update on sm.parent
	p.physics_update(delta)
