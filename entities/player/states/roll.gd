class_name PlayerRoll extends State

@export var ROLL_SPEED : float
@export var ROLL_FRICTION : float
@export var ROLL_DURATION : float = 0.4
@export var PLAYER_HURTBOX : HurtboxComponent

@onready var sm: PlayerStateMachine = get_parent()
var p
var roll_direction : Vector2
var roll_timer : float = 0
var rotation_direction : float
var did_slow_friction : bool = false

func enter() -> void:
	sm.animatedSprite.play("roll")
	did_slow_friction = false
	p = sm.player
	roll_timer = ROLL_DURATION
	set_invincible(true)
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	roll_direction = input_dir if input_dir != Vector2.ZERO else (p.get_aim_position() - p.global_position).normalized()
	
	# Determine rotation direction based on facing and movement
	rotation_direction = -1.0 if p.is_walking_backwards else 1.0
	if p.is_walking_left:
		rotation_direction *= -1
	
	p.extra_velocity += ROLL_SPEED * roll_direction

func physics_update(delta: float) -> void:
	roll_timer -= delta
	#sm.animatedSprite.rotation_degrees += rotation_direction * (360.0 * delta / ROLL_DURATION)

	if roll_timer <= ROLL_DURATION / 2 and !did_slow_friction:
		did_slow_friction = true
		p.extra_velocity -= ROLL_FRICTION * roll_direction
	
	if roll_timer <= 0:
		sm.animatedSprite.rotation_degrees = 0
		set_invincible(false)
		sm.on_child_transition(self, "Walk")
	
	p.physics_update(delta)

func exit() -> void:
	p.rotation_degrees = 0
	set_invincible(false)

func set_invincible(value: bool) -> void:
	PLAYER_HURTBOX.set_collision_mask_value(2, !value)
