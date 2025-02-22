extends CharacterBody2D
class_name Player

var speed : int = 1200
var roll_speed : int = 2000
var roll_duration : float = 0.2
var roll_cooldown : float = 0.2
var can_roll : bool = true
var is_rolling : bool = false
var roll_direction : Vector2
var screen_size : Vector2
var shield_on : bool = false

func _ready():
	$AnimatedSprite2D.play()
	$RollTimer.wait_time = roll_duration
	$RollCooldownTimer.wait_time = roll_cooldown

func get_input():
	if !is_rolling:
		var input_dir = Input.get_vector("left", "right", "up", "down")
		velocity = input_dir.normalized() * speed
		
		if Input.is_action_just_pressed("roll") and can_roll and input_dir != Vector2.ZERO:
			start_roll(input_dir)

func start_roll(direction: Vector2) -> void:
	is_rolling = true
	can_roll = false
	roll_direction = direction
	$RollTimer.start()

func is_moving_backwards(direction: Vector2, facing_left: bool) -> bool:
	if facing_left:
		return direction.x > 0
	return direction.x < 0

func _physics_process(_delta):
	get_input()
	
	if is_rolling:
		velocity = roll_direction * roll_speed
		var facing_left = get_global_mouse_position().x < global_position.x
		var rotation_direction = -1 if facing_left else 1
		if is_moving_backwards(roll_direction, facing_left):
			rotation_direction *= -1
		$AnimatedSprite2D.rotation += 0.5 * rotation_direction
	else:
		$AnimatedSprite2D.rotation = 0
		
	move_and_slide()
	check_mouse_position()
	
	if !is_rolling:
		if velocity.length() != 0:
			$AnimatedSprite2D.play('walk')
		else:
			$AnimatedSprite2D.play('default')

func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func on_weapon_fired():
	$Camera2D.apply_shake(5)

func check_mouse_position():
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false

func _on_damage(health, MAX_HEALTH, damage) -> void:
	if !is_rolling:
		$AnimatedSprite2D/AnimationPlayer.play("RESET")
		$AnimatedSprite2D/AnimationPlayer.play("flash")
		$Camera2D.apply_shake(10)
		$"../CanvasLayer/HUD".update_health(health, MAX_HEALTH)

func _on_roll_timer_timeout() -> void:
	$RollTimer.stop()
	is_rolling = false
	
	$RollCooldownTimer.stop()
	$RollCooldownTimer.start()
	
func _on_roll_cooldown_timer_timeout() -> void:
	$RollCooldownTimer.stop()
	can_roll = true
	
