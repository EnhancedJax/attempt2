extends State
class_name PlayerIdle

@onready var sm: PlayerStateMachine = get_parent()
var p

func enter():
	sm.animatedSprite.play("idle")
	p = sm.player
	
func physics_update(delta : float):
	var input_direction = Input.get_vector("left", "right", "up", "down")

	if input_direction != Vector2.ZERO:
		sm.on_child_transition(self, "Walk")
	else:
		p.velocity = p.velocity.move_toward(Vector2.ZERO, p.FRICTION * delta)
	
	p.physics_update(delta)
	
	if Input.is_action_just_pressed("roll") and sm.can_roll:
		sm.can_roll = false
		sm.roll_cooldown.start()
		sm.on_child_transition(self, "roll")


func _on_walk_signal_transitioned() -> void:
	print('test')
