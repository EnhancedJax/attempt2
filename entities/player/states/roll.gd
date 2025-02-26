class_name PlayerRoll extends State

@export var ROLL_SPEED : float = 1500
@export var ROLL_DURATION : float = 0.2
@export var PLAYER_HITBOX : HitboxComponent

@onready var sm: PlayerStateMachine = get_parent()
var roll_direction : Vector2
var roll_timer : float = 0
var rotation_direction : float

func enter() -> void:
	roll_timer = ROLL_DURATION
	set_invincible(true)
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	roll_direction = input_dir if input_dir != Vector2.ZERO else (sm.player.get_aim_position() - sm.player.global_position).normalized()
	
	# Determine rotation direction based on facing and movement
	rotation_direction = -1.0 if sm.player.is_walking_backwards else 1.0
	if sm.player.is_walking_left:
		rotation_direction *= -1

func physics_update(delta: float) -> void:
	roll_timer -= delta
	sm.player.velocity = roll_direction * ROLL_SPEED
	sm.animatedSprite.rotation_degrees += rotation_direction * (360.0 * delta / ROLL_DURATION)
	
	if roll_timer <= 0:
		sm.animatedSprite.rotation_degrees = 0
		set_invincible(false)
		sm.on_child_transition(self, "Walk")

func exit() -> void:
	sm.player.rotation_degrees = 0
	set_invincible(false)

func set_invincible(value: bool) -> void:
	PLAYER_HITBOX.set_collision_layer_value(6, !value)
