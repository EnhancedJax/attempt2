extends State

@onready var sm: StateMachine = get_parent()

func enter():
	sm.animatedSprite.play("default")
	
func physics_update(_delta : float):
	pass
