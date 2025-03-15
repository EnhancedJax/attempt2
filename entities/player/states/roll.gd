class_name PlayerRoll extends State

@export var ROLL_SPEED : float
@export var ROLL_DURATION : float = 0.4
@export var PLAYER_HURTBOX : HurtboxComponent
@export var curve: Curve

@onready var sm: PlayerStateMachine = get_parent()
var p
var roll_direction : Vector2
var roll_timer : float = 0
var rotation_direction : float

func enter() -> void:
	sm.animatedSprite.play("roll")
	p = sm.player
	roll_timer = ROLL_DURATION
	set_invincible(true)

	p.weapon_node.visible = false
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	roll_direction = input_dir if input_dir != Vector2.ZERO else (p.get_aim_position() - p.global_position).normalized()
	
	# Determine rotation direction based on facing and movement
	rotation_direction = -1.0 if p.is_walking_backwards else 1.0
	if p.is_walking_left:
		rotation_direction *= -1
	
	# Instead of adding to extra_velocity, we'll set the velocity directly
	p.velocity = roll_direction * ROLL_SPEED
	p.extra_velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	
	if roll_timer <= 0:
		sm.animatedSprite.rotation_degrees = 0
		set_invincible(false)
		sm.on_child_transition(self, "Walk")
		return
	
	# Calculate the normalized time (1->0) for curve sampling
	var curve_time = roll_timer / ROLL_DURATION
	# Sample the curve and apply to roll speed
	var speed_multiplier = 1-curve.sample_baked(curve_time)
	print("Coordinates:", curve_time, speed_multiplier)
	# Override the player's velocity with curve-modified speed
	p.velocity = roll_direction * (ROLL_SPEED * speed_multiplier)
	p.extra_velocity = Vector2.ZERO
	p.move_and_slide()
	
	roll_timer -= delta

func exit() -> void:
	p.rotation_degrees = 0
	set_invincible(false)
	p.weapon_node.visible = true

func set_invincible(value: bool) -> void:
	PLAYER_HURTBOX.set_collision_mask_value(2, !value)
