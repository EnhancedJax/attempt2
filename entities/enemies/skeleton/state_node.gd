extends StateMachine

@export var animatedSprite : AnimatedSprite2D
@export var animator : AnimationPlayer
@onready var parent : EntityBase = get_parent()

func _ready() -> void:
	super._ready()
	parent.signal_death.connect(_on_parent_death)

func _on_parent_death():
	on_child_transition(current_state, "Death")
