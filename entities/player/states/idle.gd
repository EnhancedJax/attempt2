extends State
class_name PlayerIdle

@onready var sm: PlayerStateMachine = get_parent()

func enter():
	sm.animatedSprite.play("default")
	
func physics_update(_delta : float):
	if(Input.get_vector("left", "right", "up", "down")):
		sm.on_child_transition(self, "Walk")
	
	if Input.is_action_just_pressed("roll") and sm.can_roll:
		sm.can_roll = false
		sm.roll_cooldown.start()
		sm.on_child_transition(self, "roll")


func _on_walk_signal_transitioned() -> void:
	print('test')
