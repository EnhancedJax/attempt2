class_name PlayerWalk extends State

@export var MAX_SPEED : float
@onready var sm: PlayerStateMachine = get_parent()
var p

func enter():
	sm.animatedSprite.play("walk")
	p = sm.player

func update(delta: float):
	if p.weapon_node:
		p.weapon_node.handle_use(delta, false)
		
func physics_update(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")

	if input_direction != Vector2.ZERO:
		p.velocity = p.velocity.move_toward(MAX_SPEED * input_direction, 40000 * delta)
	else:
		sm.on_child_transition(self, "Idle")
	
	p.physics_update(delta)
	
	if Input.is_action_just_pressed("roll") and sm.can_roll:
		sm.can_roll = false
		sm.roll_cooldown.start()
		sm.on_child_transition(self, "roll")
