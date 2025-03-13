class_name EntityBase extends CharacterBody2D

const FLOATING_NUMBER = preload("res://scenes/misc/floating_number.tscn")

@export var is_protagonist: bool = true # changes weapon class

signal signal_death()

@onready var animatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D
@onready var animationPlayer: AnimationPlayer = $AnimatedSprite2D/AnimationPlayer
@onready var damageNumbersOrigin : Marker2D = $DamageNumbersOrigin
@onready var weaponOrigin : Marker2D = $WeaponOrigin
@onready var _health : HealthComponent = $HealthComponent
@onready var _hurtbox : Area2D = $HurtboxComponent

var is_walking_left : bool = false
var is_walking_backwards : bool = false
var is_invincible : bool = false
var weapon_node : Node2D

const FRICTION: float = 40000.0
var extra_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	animatedSprite2D.play("default")
	_health.connect("signal_health_deducted", rsignal_health_deducted)
	_health.connect("signal_health_depleted", rsignal_health_depleted)
	_hurtbox.connect("signal_hit", rsignal_hitbox_hit)

func _process(_delta: float) -> void:
	is_walking_left = velocity.x < 0
	is_walking_backwards = velocity.x > 0 if is_walking_left else velocity.x < 0
	animatedSprite2D.flip_h = get_aim_position().x < global_position.x

func physics_update(delta: float) -> void:
	var extra_velocity_move_toward = Vector2.ZERO
	if extra_velocity:
		extra_velocity_move_toward = lerp(extra_velocity, Vector2.ZERO, 0.1)
		extra_velocity = Vector2.ZERO
	
	velocity = velocity + extra_velocity_move_toward
	move_and_slide()

# /* ------------- Methods ------------ */

func get_aim_position() -> Vector2: 
	var player = Main.player
	if player:
		return player.global_position
	else:
		return Vector2.ZERO

func rsignal_hitbox_hit(attack: AttackBase):
	if is_invincible:
		return
	
	# Apply knockback force
	apply_force(attack.towards_vector * attack.knockback)
	# show_damage_number(attack.damage)
	_health.take_damage(attack.damage)

func rsignal_health_deducted(health: int, max_health: int):
	animationPlayer.play("RESET")
	animationPlayer.play("take_attack")

func rsignal_health_depleted():
	do_die()

func rsignal_weapon_did_use(attack: AttackBase):
	pass

func do_die():
	signal_death.emit()
	queue_free()

# /* ------------ Interals ------------ */

# overriden by the player class for custom implementation. Still valid for enemies and allies.
func equip_weapon(weapon_id: int) -> Lookup.WeaponType:
	var weapon = Lookup.get_weapon(weapon_id, is_protagonist)
	if weapon_node:
		weapon_node.queue_free()
	
	weapon_node = weapon.scene.instantiate()
	weapon_node.connect("signal_weapon_did_use", rsignal_weapon_did_use)
	weapon_node.position = weaponOrigin.position
	weapon_node.visible = false
	add_child(weapon_node)

	return weapon

func apply_force(force: Vector2) -> void:
	extra_velocity += force

func show_damage_number(damage: int):
	var damage_number = FLOATING_NUMBER.instantiate()
	get_tree().root.add_child(damage_number)
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
