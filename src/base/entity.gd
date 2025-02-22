class_name EntityBase extends CharacterBody2D

const FLOATING_NUMBER = preload("res://scenes/floating_number.tscn")
@export var MAX_HEALTH : int = 1
@export var INITIAL_HEALTH : int = 1
@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D
@onready var animationPlayer: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
@onready var damageNumbersOrigin : Node = $DamageNumbersOrigin
var health : int 
var is_walking_left : bool = false
var is_walking_backwards : bool = false
var is_invincible : bool = false
var is_dead : bool = false
var weapon_node : Node2D

const FRICTION: float = 1000.0  # Base friction force
const FORCE_THRESHOLD: float = 5.0  # Minimum velocity to apply friction

func _ready() -> void:
	health = INITIAL_HEALTH
	animatedSprite2D.play("default")

func _process(delta: float) -> void:
	is_walking_left = velocity.x < 0
	is_walking_backwards = is_moving_backwards(is_walking_left)
	animatedSprite2D.flip_h = get_aim_position().x < global_position.x

func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func _physics_process(delta: float) -> void:
	apply_friction(delta)
	move_and_slide()

func apply_friction(delta: float) -> void:
	if velocity.length() < FORCE_THRESHOLD:
		velocity = Vector2.ZERO
		return
		
	var friction_force = velocity.normalized() * -FRICTION * delta
	if friction_force.length() > velocity.length():
		velocity = Vector2.ZERO
	else:
		velocity += friction_force

func is_moving_backwards(walking_left: bool) -> bool:
	if walking_left:
		return velocity.x > 0
	return velocity.x < 0

func equip_weapon(weapon: Array):
	print("Equipping weapon: ", weapon[1])
	if weapon_node:
		weapon_node.queue_free()
	
	weapon_node = weapon[0].new()
	weapon_node.WEAPON = weapon[1]
	add_child(weapon_node)

func take_attack(attack: Attack):
	if is_invincible:
		return
	health -= attack.damage
	animationPlayer.play("RESET")
	animationPlayer.play("take_attack")
	
	# Apply knockback force
	apply_force(attack.direction * attack.knockback)
	
	show_damage_number(attack.damage)

	if health <= 0:
		do_die()

func apply_force(force: Vector2) -> void:
	velocity += force

func do_die():
	is_dead = true
	queue_free()

func show_damage_number(damage: int):
	var damage_number = FLOATING_NUMBER.instantiate()
	get_tree().root.add_child(damage_number)
	add_child(damage_number)
	damage_number.global_position = damageNumbersOrigin.global_position
	damage_number.get_child(0).text = str(damage)

	var random_x_offset = randf_range(-100, 100)
	var random_y_offset = randf_range(-100, 100)

	var tween = get_tree().create_tween()
	tween.parallel().tween_property(damage_number, "position:y", damage_number.position.y + random_y_offset, 1.0).set_trans(tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(damage_number, "modulate:a", 0, 1.0).set_trans(tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(damage_number, "scale", Vector2.ZERO, 1.0).set_trans(tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(damage_number, "position:x", damage_number.position.x + random_x_offset, 1.0).set_trans(tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(damage_number, "queue_free"))
	tween.play()
