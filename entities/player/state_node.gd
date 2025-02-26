class_name PlayerStateMachine extends StateMachine

@export var animatedSprite : AnimatedSprite2D
@export var animator : AnimationPlayer
@onready var player : Player = get_parent()
@onready var roll_cooldown : Timer = $RollCooldown
var can_roll : bool = true

func _ready():
	super._ready()
	roll_cooldown.wait_time = 0.5
	roll_cooldown.one_shot = true
	roll_cooldown.timeout.connect(_on_roll_cooldown_timeout)

func _on_roll_cooldown_timeout() -> void:
	can_roll = true
