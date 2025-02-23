class_name PlayerWalk extends State

@export var MAX_SPEED : float = 1200

@onready var roll_cooldown : Timer = $RollCooldown
var can_roll : bool = false

@onready var sm: PlayerStateMachine = get_parent()

func _ready():
	roll_cooldown.wait_time = 0.5
	roll_cooldown.one_shot = true
	roll_cooldown.timeout.connect(_on_roll_cooldown_timeout)

func enter():
	sm.animatedSprite.play("walk")
	can_roll = roll_cooldown.is_stopped()

func _on_roll_cooldown_timeout() -> void:
	can_roll = true

func physics_update(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	if input_dir != Vector2.ZERO:
		 # Set velocity directly to max speed in input direction
		sm.player.velocity = input_dir.normalized() * MAX_SPEED
	else:
		# Stop immediately when no input
		sm.player.velocity = Vector2.ZERO
		sm.on_child_transition(self, "Idle")
		return
	
	if Input.is_action_just_pressed("roll") and can_roll and input_dir != Vector2.ZERO:
		can_roll = false
		roll_cooldown.start()
		sm.on_child_transition(self, "roll")
