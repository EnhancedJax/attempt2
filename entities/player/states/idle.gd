extends State
class_name PlayerIdle

func enter():
	sm.animatedSprite.play("idle")

func update(delta: float):
	if p.weapon_node:
		p.weapon_node.handle_use(delta, p.is_just_pressed_fire, p.is_holding_down_fire, false)
		
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
