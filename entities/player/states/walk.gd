class_name PlayerWalk extends State

@export var MAX_SPEED : float
@onready var sm: PlayerStateMachine = get_parent()

func enter():
	sm.animatedSprite.play("walk")

func physics_update(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		sm.player.velocity = input_dir.normalized() * MAX_SPEED
	else:
		sm.player.velocity = Vector2.ZERO
		sm.on_child_transition(self, "Idle")
		return
	
	if Input.is_action_just_pressed("roll") and sm.can_roll:
		sm.can_roll = false
		sm.roll_cooldown.start()
		sm.on_child_transition(self, "roll")
