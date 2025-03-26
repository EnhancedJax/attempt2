extends State

@export var fire_duration_1 : float = 1 # seconds
@export var fire_wait : float = 0.5
@export var fire_duration_2 : float = 3
@export var walk_speed : float = 80

var fire_timer : float = 0.0
var firing : bool = false
var cooldown_timer : float = 0.0
var phase : int = 0

func enter() -> void:
	fire_timer = 0.0
	cooldown_timer = 0.0
	phase = 0
	firing = true

func update(delta: float) -> void:
	if phase == 0: # Fire mode 1
		p.weapon_node.handle_use_custom(delta, 1, true)
		fire_timer += delta
		if fire_timer >= fire_duration_1:
			fire_timer = 0.0
			phase = 1
			firing = false
	elif phase == 1: # Wait
		p.weapon_node.handle_use_custom(delta, 1, false)
		cooldown_timer += delta
		if cooldown_timer >= fire_wait:
			cooldown_timer = 0.0
			phase = 2
			firing = true
	elif phase == 2: # Fire mode 2
		p.weapon_node.handle_use_custom(delta, 2, true)
		fire_timer += delta
		if fire_timer >= fire_duration_2:
			fire_timer = 0.0
			phase = 3
			firing = false
	elif phase == 3: # Transition back to Hostile
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
