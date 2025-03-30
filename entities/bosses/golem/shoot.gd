extends State

@export var fire_wait : float = 1.5
@export var walk_speed : float = 80

var cooldown_timer : float = 0.0

func enter() -> void:
	cooldown_timer = 0.0
	# Fire mode 1
	p.weapon_node.handle_use_custom(0, 1, true)

func update(delta: float) -> void:
	cooldown_timer += delta
	if cooldown_timer >= fire_wait:
		# Transition back to Hostile
		sm.on_child_transition(self, "Hostile")
		
func physics_update(delta : float):
	var player = Main.player
	
	# Calculate direction to player
	var to_player = player.global_position - sm.parent.global_position
	var direction = to_player.normalized()
	
	# Move towards player
	p.velocity = direction * walk_speed
	
	# Call physics_update on sm.parent
	p.physics_update(delta)
