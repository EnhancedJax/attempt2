extends WeaponBase

@export var spawner_1 : BulletSpawner
@export var spawner_2 : BulletSpawner

var _attack_1_firing : bool = false

func handle_use_custom(delta: float, mode: int, firing: bool): # TODO: Standardize
	if mode == 1:
		handle_attack_1()
		if not _attack_1_firing:
			_attack_1_firing = true
			$AnimatedSprite2D.play("fire_1")
		else:
			if _attack_1_firing:
				$AnimatedSprite2D.play("idle")
				_attack_1_firing = false
	elif mode == 2:
		handle_attack_2()
	

func handle_attack_1() -> void:
	spawner_1.shoot()
	signal_weapon_did_use.emit(_calculate_kickback_vector())

func handle_attack_2() -> void:
	$AnimatedSprite2D.play("charge")
	await get_tree().create_timer(0.5).timeout
	spawner_2.shoot()
	signal_weapon_did_use.emit(_calculate_kickback_vector())
