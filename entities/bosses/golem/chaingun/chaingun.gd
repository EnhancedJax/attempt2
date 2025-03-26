extends WeaponBase

@export var ATTACK : AttackBase
@export var spread : float = 40
@export var attack_1_firing_handler : FiringHandlerBase
@export var attack_1_bullet_spawner : RayCast2D
@export var attack_2_firing_handler : FiringHandlerBase
@export var attack_2_bullet_spawner : RayCast2D

var _attack_1_firing : bool = false

func _ready() -> void:
	attack_1_bullet_spawner.register(ATTACK)
	attack_2_bullet_spawner.register(ATTACK)

func handle_use_custom(delta: float, mode: int, firing: bool): # TODO: Standardize
	if mode == 1:
		if attack_1_firing_handler.is_to_attack(delta, false, false, firing):
			handle_attack_1()
			if not _attack_1_firing:
				_attack_1_firing = true
				$AnimatedSprite2D.play("fire_1")
		else:
			if _attack_1_firing:
				$AnimatedSprite2D.play("idle")
				_attack_1_firing = false
	elif mode == 2:
		if attack_2_firing_handler.is_to_attack(delta, false, false, firing):
			handle_attack_2()
	

func handle_attack_1() -> void:
	randomize()
	var towards = rotation + deg_to_rad(randf_range(-spread, spread))
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = attack_1_bullet_spawner.shoot(towards)
	if shot: 
		emit_signal("signal_weapon_did_use", atk)

func handle_attack_2() -> void:
	$AnimatedSprite2D.play("charge")
	await get_tree().create_timer(0.5).timeout
	var towards = rotation
	var towards_vector = Vector2(cos(towards), sin(towards))
	var atk = ATTACK.duplicate()
	atk.towards_vector = towards_vector
	var shot = attack_2_bullet_spawner.shoot(towards)
	if shot: 
		emit_signal("signal_weapon_did_use", atk)
