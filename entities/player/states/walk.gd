class_name PlayerWalk extends State

@export var BASE_SPEED : float
@export var FAST_SPEED : float

func enter():
	sm.animatedSprite.play("walk")
	p = sm.player

func update(delta: float):
	if p.weapon_node:
		p.weapon_node.handle_use(delta, p.is_just_pressed_fire, p.is_holding_down_fire, false)
		
func physics_update(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")

	if input_direction != Vector2.ZERO:
		var speed : float = FAST_SPEED
		if Main.player_room_at and Main.player_room_at.room_state == 1:
			speed = BASE_SPEED
		p.velocity = p.velocity.move_toward(speed * input_direction, 40000 * delta)
	else:
		sm.on_child_transition(self, "Idle")
	
	p.physics_update(delta)
	
	if Input.is_action_just_pressed("roll") and sm.can_roll:
		sm.can_roll = false
		sm.roll_cooldown.start()
		sm.on_child_transition(self, "roll")
