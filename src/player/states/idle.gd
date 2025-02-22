extends State
class_name PlayerIdle

@onready var sm: PlayerStateMachine = get_parent()

func enter():
	sm.animatedSprite.play("default")
	
func physics_update(_delta : float):
	if(Input.get_vector("left", "right", "up", "down")):
		sm.on_child_transition(self, "Walk")


func _on_walk_signal_transitioned() -> void:
	print('test')
