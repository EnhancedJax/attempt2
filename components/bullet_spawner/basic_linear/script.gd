extends RayCast2D

@export var rotate : bool = true
var BULLET : PackedScene
var ATTACK : BulletType

signal signal_shot()

func shoot(towards: float) -> bool:
	var did_shoot = not is_colliding()
	if did_shoot and BULLET:
		var atk = ATTACK.duplicate()
		atk.towards_vector = Vector2(cos(towards), sin(towards))
		var bullet = BULLET.instantiate()
		bullet.register_attack(atk)
		get_tree().root.add_child(bullet)

		var global_target_offset = target_position.rotated(towards) * abs(global_scale)
		bullet.global_position = global_position + global_target_offset
		signal_shot.emit()
	return did_shoot
