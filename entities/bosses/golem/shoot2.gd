extends State

@export var fire_wait : float = 1.5
@export var wait_between_shotgun : float = 1.5
@export var walk_speed : float = 80

var cooldown_timer : float = 0.0
var phase : int = 0

func enter() -> void:
	cooldown_timer = 0.0
	phase = 0
	# Fire mode 2 - first time
	p.weapon_node.handle_use_custom(0, 2, true)
	phase = 1

func update(delta: float) -> void:
	if phase == 1: # Wait between shotgun shots
		cooldown_timer += delta
		if cooldown_timer >= wait_between_shotgun:
			cooldown_timer = 0.0
			# Fire mode 2 - second time
			p.weapon_node.handle_use_custom(0, 2, true)
			phase = 2
	elif phase == 2: # Wait after second shotgun shot
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
