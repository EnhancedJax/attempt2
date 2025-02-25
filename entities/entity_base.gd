class_name EntityBase extends CharacterBody2D

const FLOATING_NUMBER = preload("res://scenes/floating_number.tscn")

@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D
@onready var animationPlayer: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
@onready var damageNumbersOrigin : Node = $DamageNumbersOrigin
@onready var _health : HealthComponent = $HealthComponent
@onready var _hitbox : Area2D = $HitboxComponent

var is_walking_left : bool = false
var is_walking_backwards : bool = false
var is_invincible : bool = false
var weapon_node : Node2D

const FRICTION: float = 1000.0  # Base friction force
const FORCE_THRESHOLD: float = 5.0  # Minimum velocity to apply friction

func _ready() -> void:
	animatedSprite2D.play("default")
	_health.connect("signal_health_deducted", rsignal_health_deducted)
	_health.connect("signal_health_depleted", rsignal_health_depleted)
	_hitbox.connect("signal_hit", rsignal_hitbox_hit)

func _process(_delta: float) -> void:
	is_walking_left = velocity.x < 0
	is_walking_backwards = velocity.x > 0 if is_walking_left else velocity.x < 0
	animatedSprite2D.flip_h = get_aim_position().x < global_position.x

func _physics_process(delta: float) -> void:
	apply_friction(delta)
	move_and_slide()

# /* ------------- Methods ------------ */

func get_aim_position() -> Vector2: 
	var player = Main.player
	if player:
		return player.global_position
	else:
		return Vector2.ZERO

func rsignal_hitbox_hit(attack: AttackBase):
	print('Entity was hit')
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)
	show_damage_number(attack.damage)
	_health.take_damage(attack.damage)

func rsignal_health_deducted(health: int, max_health: int):
	animationPlayer.play("RESET")
	animationPlayer.play("take_attack")

func rsignal_health_depleted():
	do_die()

func rsignal_weapon_did_use(attack: AttackBase):
	print('Entity used weapon with attack: ', attack)

func do_die():
	queue_free()

# /* ------------ Interals ------------ */

func apply_friction(delta: float) -> void:
	if velocity.length() < FORCE_THRESHOLD:
		velocity = Vector2.ZERO
		return
		
	var friction_force = velocity.normalized() * -FRICTION * delta
	if friction_force.length() > velocity.length():
		velocity = Vector2.ZERO
	else:
		velocity += friction_force

func equip_weapon(weapon: PackedScene):
	print("Equipping weapon: ", weapon)
	if weapon_node:
		weapon_node.queue_free()
	
	weapon_node = weapon.instantiate()
	connect("signal_weapon_did_use", rsignal_weapon_did_use)
	add_child(weapon_node)

func apply_force(force: Vector2) -> void:
	velocity += force

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
